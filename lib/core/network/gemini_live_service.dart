import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Typed events emitted by [GeminiLiveService] so callers never touch the
/// raw Gemini Live wire protocol (JSON over WebSocket).
sealed class GeminiLiveEvent {}

class GeminiLiveReady extends GeminiLiveEvent {}

class GeminiLiveModelAudioChunk extends GeminiLiveEvent {
  final Uint8List pcm;
  GeminiLiveModelAudioChunk(this.pcm);
}

class GeminiLiveInterrupted extends GeminiLiveEvent {}

class GeminiLiveTurnComplete extends GeminiLiveEvent {}

class GeminiLiveTranscript extends GeminiLiveEvent {
  final bool isUser;
  final String text;
  GeminiLiveTranscript({required this.isUser, required this.text});
}

class GeminiLiveToolCall extends GeminiLiveEvent {
  final String id;
  final String category;
  final String description;
  GeminiLiveToolCall({required this.id, required this.category, required this.description});
}

class GeminiLiveError extends GeminiLiveEvent {
  final String message;
  GeminiLiveError(this.message);
}

class GeminiLiveClosed extends GeminiLiveEvent {}

/// Categories mirrored from `MockData.incidentCategories` titles, so a
/// voice-reported category folds into the description with the exact same
/// labels the manual wizard uses (see `create_report_page.dart`).
const List<String> geminiReportCategories = [
  'Robo',
  'Accidente',
  'Persona sospechosa',
  'Violencia',
  'Incendio',
  'Emergencia médica',
  'Vandalismo',
  'Otro',
];

const String _geminiLiveModel = 'models/gemini-3.1-flash-live-preview';

const String _systemInstruction =
    'Eres un asistente de emergencias de la app Arconte, en Cochabamba, Bolivia. '
    'Tu tarea es ayudar a un ciudadano a reportar una emergencia hablando con él por voz, '
    'de forma calmada y natural. Dejá que la persona explique lo que pasó con sus propias '
    'palabras; si falta información clave (qué ocurrió, gravedad) hacé preguntas breves y '
    'concretas, una a la vez. No pidas la ubicación: ya la tenemos. Cuando tengas una '
    'categoría clara y una descripción suficiente del incidente, llamá a la función '
    'submit_report con esos datos y avisá a la persona que estás enviando el reporte.';

/// Thin WebSocket client for Gemini's Live API (`BidiGenerateContent`).
/// There is no official Dart SDK for this API, so the message shapes here
/// are implemented directly from Google's public reference docs.
class GeminiLiveService {
  final String apiKey;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  final StreamController<GeminiLiveEvent> _controller = StreamController<GeminiLiveEvent>.broadcast();

  GeminiLiveService({required this.apiKey});

  Stream<GeminiLiveEvent> get events => _controller.stream;

  Future<void> connect() async {
    final uri = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;
      _channelSubscription = channel.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('GeminiLiveService: socket error: $error');
          _controller.add(GeminiLiveError(error.toString()));
        },
        onDone: () {
          debugPrint(
            'GeminiLiveService: socket closed — code=${channel.closeCode} reason=${channel.closeReason}',
          );
          _controller.add(GeminiLiveClosed());
        },
      );

      _send({
        'setup': {
          'model': _geminiLiveModel,
          'generationConfig': {
            'responseModalities': ['AUDIO'],
          },
          'systemInstruction': {
            'parts': [
              {'text': _systemInstruction},
            ],
          },
          'tools': [
            {
              'functionDeclarations': [
                {
                  'name': 'submit_report',
                  'description': 'Envía el reporte de emergencia una vez reunida suficiente información por voz.',
                  'parameters': {
                    'type': 'OBJECT',
                    'properties': {
                      'category': {
                        'type': 'STRING',
                        'enum': geminiReportCategories,
                      },
                      'description': {
                        'type': 'STRING',
                        'description': 'Resumen claro en español de lo que reportó el ciudadano.',
                      },
                    },
                    'required': ['category', 'description'],
                  },
                },
              ],
            },
          ],
          'inputAudioTranscription': <String, dynamic>{},
          'outputAudioTranscription': <String, dynamic>{},
        },
      });
    } catch (e) {
      _controller.add(GeminiLiveError(e.toString()));
    }
  }

  void sendAudioChunk(Uint8List pcm16Chunk) {
    _send({
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcm16Chunk),
          'mimeType': 'audio/pcm;rate=16000',
        },
      },
    });
  }

  void sendToolResponse(String callId, {required bool success}) {
    _send({
      'toolResponse': {
        'functionResponses': [
          {
            'id': callId,
            'name': 'submit_report',
            'response': {'result': success ? 'ok' : 'error'},
          },
        ],
      },
    });
  }

  void _send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void _handleMessage(dynamic raw) {
    final Map<String, dynamic> message;
    try {
      final decoded = raw is String ? raw : utf8.decode(raw as List<int>);
      message = jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GeminiLiveService: could not decode message: $raw ($e)');
      return;
    }

    debugPrint('GeminiLiveService: <- ${jsonEncode(message)}');

    final error = message['error'] as Map<String, dynamic>?;
    if (error != null) {
      final code = error['code'];
      final status = error['status'];
      final msg = error['message'] as String? ?? 'error desconocido';
      _controller.add(GeminiLiveError('[$code $status] $msg'));
      return;
    }

    if (message.containsKey('setupComplete')) {
      _controller.add(GeminiLiveReady());
      return;
    }

    final toolCall = message['toolCall'] as Map<String, dynamic>?;
    if (toolCall != null) {
      final calls = toolCall['functionCalls'] as List<dynamic>? ?? const [];
      for (final call in calls) {
        final callMap = call as Map<String, dynamic>;
        if (callMap['name'] != 'submit_report') continue;
        final args = callMap['args'] as Map<String, dynamic>? ?? const {};
        _controller.add(GeminiLiveToolCall(
          id: callMap['id'] as String? ?? '',
          category: args['category'] as String? ?? 'Otro',
          description: args['description'] as String? ?? '',
        ));
      }
      return;
    }

    final serverContent = message['serverContent'] as Map<String, dynamic>?;
    if (serverContent == null) return;

    if (serverContent['interrupted'] == true) {
      _controller.add(GeminiLiveInterrupted());
    }

    final inputTranscription = serverContent['inputTranscription'] as Map<String, dynamic>?;
    final inputText = inputTranscription?['text'] as String?;
    if (inputText != null && inputText.isNotEmpty) {
      _controller.add(GeminiLiveTranscript(isUser: true, text: inputText));
    }

    final outputTranscription = serverContent['outputTranscription'] as Map<String, dynamic>?;
    final outputText = outputTranscription?['text'] as String?;
    if (outputText != null && outputText.isNotEmpty) {
      _controller.add(GeminiLiveTranscript(isUser: false, text: outputText));
    }

    final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
    final parts = modelTurn?['parts'] as List<dynamic>? ?? const [];
    for (final part in parts) {
      final inlineData = (part as Map<String, dynamic>)['inlineData'] as Map<String, dynamic>?;
      final mimeType = inlineData?['mimeType'] as String?;
      final data = inlineData?['data'] as String?;
      if (data != null && (mimeType?.startsWith('audio/pcm') ?? false)) {
        _controller.add(GeminiLiveModelAudioChunk(base64Decode(data)));
      }
    }

    if (serverContent['turnComplete'] == true) {
      _controller.add(GeminiLiveTurnComplete());
    }
  }

  Future<void> close() async {
    await _channelSubscription?.cancel();
    await _channel?.sink.close();
    await _controller.close();
  }
}
