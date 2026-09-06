import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_service.dart';
import '../../core/services/category_override_store.dart';
import '../../core/services/report_events.dart';
import '../../mock/models.dart';
import '../dtos/emergency_dto.dart';
import '../dtos/emergency_message_dto.dart';
import '../dtos/evidence_dto.dart';
import '../mappers.dart';
import 'citizen_repository.dart';

const _videoExtensions = {'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm', '3gp'};

/// Deriva el `fileType` ('IMAGE' o 'VIDEO') que espera el backend a partir de
/// la extensión del archivo/URL de evidencia.
String inferEvidenceFileType(String path) {
  final dotIndex = path.lastIndexOf('.');
  if (dotIndex == -1) return 'IMAGE';
  final ext = path.substring(dotIndex + 1).toLowerCase();
  return _videoExtensions.contains(ext) ? 'VIDEO' : 'IMAGE';
}

/// URL de un frame estático (JPG) de un video ya subido a Cloudinary:
/// Cloudinary sirve automáticamente un frame cuando se pide un formato de
/// imagen sobre la misma URL de un video, así que solo hace falta cambiar la
/// extensión. Devuelve null para rutas locales (todavía no subidas).
String? cloudinaryVideoThumbnailUrl(String url) {
  if (!url.startsWith('http')) return null;
  final dotIndex = url.lastIndexOf('.');
  if (dotIndex == -1) return null;
  return '${url.substring(0, dotIndex)}.jpg';
}

class EmergencyRepository {
  final Dio _dio = ApiClient.instance.dio;
  final CitizenRepository _citizenRepository = CitizenRepository();

  Future<String> _reporterName() async {
    final citizen = await _citizenRepository.getProfile();
    return citizen.fullName;
  }

  Future<List<EmergencyDto>> _listMineDtos() async {
    final response = await _dio.get('/api/citizen/emergencies');
    final items = (response.data['emergencies'] as List<dynamic>)
        .map((e) => EmergencyDto.fromJson(e as Map<String, dynamic>))
        .toList();

    // The list endpoint omits location data; enrich each item from the
    // detail endpoint so cards/map pins have real coordinates.
    final enriched = await Future.wait(items.map((e) => _getDto(e.pkEmergency)));
    return enriched;
  }

  Future<EmergencyDto> _getDto(int id) async {
    final response = await _dio.get('/api/citizen/emergencies/$id');
    final data = response.data as Map<String, dynamic>;
    final emergencyJson = data['emergency'] as Map<String, dynamic>? ?? data;
    return EmergencyDto.fromJson(emergencyJson);
  }

  /// Incidentes recientes de TODOS los ciudadanos, sin requerir sesión.
  /// El backend no expone el nombre ni contacto del reportante en este
  /// endpoint, así que se etiquetan como "Comunidad".
  Future<List<Incident>> listPublicIncidents() async {
    final response = await _dio.get('/api/public/emergencies/map');
    final dtos = (response.data['emergencies'] as List<dynamic>)
        .map((e) => EmergencyDto.fromJson(e as Map<String, dynamic>))
        .toList();
    final overrides = await CategoryOverrideStore.loadAll();
    return dtos
        .map((dto) => emergencyToIncident(
              dto,
              reporterId: '',
              reporterName: 'Comunidad',
              typeOverride: overrides[dto.pkEmergency],
            ))
        .toList();
  }

  Future<List<Incident>> listMineIncidents() async {
    final reporterName = await _reporterName();
    final dtos = await _listMineDtos();
    final overrides = await CategoryOverrideStore.loadAll();
    return dtos
        .map((dto) => emergencyToIncident(
              dto,
              reporterId: _reporterId,
              reporterName: reporterName,
              typeOverride: overrides[dto.pkEmergency],
            ))
        .toList();
  }

  Future<List<Report>> listMineReports() async {
    final dtos = await _listMineDtos();
    final overrides = await CategoryOverrideStore.loadAll();
    return dtos.map((dto) => emergencyToReport(dto, typeOverride: overrides[dto.pkEmergency])).toList();
  }

  Future<Incident> getDetailIncident(int id) async {
    final dto = await _getDto(id);
    final overrides = await CategoryOverrideStore.loadAll();
    return emergencyToIncident(
      dto,
      // El reportante real viene del propio registro (dto.reporter), no del
      // ciudadano que está viendo el detalle — antes se usaba el perfil de la
      // sesión actual, por lo que cualquier reporte ajeno mostraba el nombre
      // de quien lo estuviera mirando.
      reporterId: '',
      reporterName: dto.reporter?.fullName.isNotEmpty == true ? dto.reporter!.fullName : 'Ciudadano',
      typeOverride: overrides[dto.pkEmergency],
    );
  }

  String get _reporterId => AuthService.currentCitizenId?.toString() ?? '';

  /// Registra que el ciudadano actual visualizó esta emergencia. El backend
  /// deduplica por (emergencia, ciudadano), así que llamar esto varias veces
  /// para el mismo reporte no infla el contador.
  Future<int> registerView(int emergencyId) async {
    final response = await _dio.post('/api/citizen/emergencies/$emergencyId/view');
    final data = response.data as Map<String, dynamic>;
    return data['viewsCount'] as int? ?? 0;
  }

  /// Alterna la confirmación (like) del ciudadano actual sobre la emergencia.
  Future<({bool liked, int likesCount})> toggleLike(int emergencyId) async {
    final response = await _dio.post('/api/citizen/emergencies/$emergencyId/like');
    final data = response.data as Map<String, dynamic>;
    return (
      liked: data['liked'] as bool? ?? false,
      likesCount: data['likesCount'] as int? ?? 0,
    );
  }

  Future<EmergencyDto> report({
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    IncidentType? category,
  }) async {
    final response = await _dio.post(
      '/api/citizen/emergency/report',
      data: {
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (category != null) 'emergencyTypeName': category.label,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final emergencyJson = data['emergency'] as Map<String, dynamic>? ?? data;
    final dto = EmergencyDto.fromJson(emergencyJson);
    // Also persist locally so this device's own map/list reflects the
    // category instantly, without waiting on a re-fetch from the backend.
    if (category != null) {
      await CategoryOverrideStore.save(dto.pkEmergency, category.value);
    }
    ReportEvents.notifySubmitted();
    return dto;
  }

  Future<List<EmergencyMessageDto>> listMessages(int emergencyId) async {
    final response = await _dio.get('/api/citizen/emergencies/$emergencyId/messages');
    return (response.data['messages'] as List<dynamic>)
        .map((e) => EmergencyMessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EmergencyMessageDto> sendMessage(int emergencyId, String message) async {
    final response = await _dio.post(
      '/api/citizen/emergencies/$emergencyId/messages',
      data: {'message': message},
    );
    return EmergencyMessageDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<EvidenceDto>> listEvidence(int emergencyId) async {
    final response = await _dio.get('/api/citizen/emergencies/$emergencyId/evidence');
    return (response.data['evidences'] as List<dynamic>)
        .map((e) => EvidenceDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sube el archivo directamente a Cloudinary (con una firma de corta
  /// duración emitida por el backend) y luego solo informa la URL resultante
  /// al backend. Los videos superan fácilmente el límite de payload (~4.5 MB)
  /// de las funciones serverless de Vercel; las imágenes comprimidas casi
  /// nunca lo hacían, por eso solo los videos fallaban antes de este cambio.
  Future<EvidenceDto> uploadEvidence(
    int emergencyId,
    File file, {
    String fileType = 'IMAGE',
    String? description,
  }) async {
    final signatureResponse = await _dio.post('/api/citizen/evidence/upload-signature');
    final signature = signatureResponse.data as Map<String, dynamic>;
    final resourceType = fileType == 'IMAGE' ? 'image' : 'video';

    final uploadData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'api_key': signature['apiKey'],
      'timestamp': signature['timestamp'].toString(),
      'signature': signature['signature'],
      'folder': signature['folder'],
    });
    final cloudinaryResponse = await Dio().post<Map<String, dynamic>>(
      'https://api.cloudinary.com/v1_1/${signature['cloudName']}/$resourceType/upload',
      data: uploadData,
    );
    final fileUrl = cloudinaryResponse.data!['secure_url'] as String;

    final response = await _dio.post(
      '/api/citizen/emergencies/$emergencyId/evidence',
      data: {
        'fileType': fileType,
        'fileUrl': fileUrl,
        if (description != null) 'description': description,
      },
    );
    return EvidenceDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Token efímero de corta duración para conectar con Gemini Live sin que
  /// la app móvil tenga que guardar la llave real de Gemini: el backend la
  /// usa server-side para emitir este token de un solo uso.
  Future<String> fetchGeminiLiveToken() async {
    final response = await _dio.post('/api/citizen/gemini/live-token');
    final data = response.data as Map<String, dynamic>;
    return data['token'] as String;
  }
}
