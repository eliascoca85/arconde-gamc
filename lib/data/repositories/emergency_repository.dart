import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_service.dart';
import '../../mock/models.dart';
import '../dtos/emergency_dto.dart';
import '../dtos/emergency_message_dto.dart';
import '../mappers.dart';
import 'citizen_repository.dart';

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

  Future<List<Incident>> listMineIncidents() async {
    final reporterName = await _reporterName();
    final dtos = await _listMineDtos();
    return dtos
        .map((dto) => emergencyToIncident(dto, reporterId: _reporterId, reporterName: reporterName))
        .toList();
  }

  Future<List<Report>> listMineReports() async {
    final dtos = await _listMineDtos();
    return dtos.map(emergencyToReport).toList();
  }

  Future<Incident> getDetailIncident(int id) async {
    final reporterName = await _reporterName();
    final dto = await _getDto(id);
    return emergencyToIncident(dto, reporterId: _reporterId, reporterName: reporterName);
  }

  String get _reporterId => AuthService.currentCitizenId?.toString() ?? '';

  Future<EmergencyDto> report({
    required String description,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await _dio.post(
      '/api/citizen/emergency/report',
      data: {
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final emergencyJson = data['emergency'] as Map<String, dynamic>? ?? data;
    return EmergencyDto.fromJson(emergencyJson);
  }

  Future<List<EmergencyMessageDto>> listMessages(int emergencyId) async {
    final response = await _dio.get('/api/citizen/emergencies/$emergencyId/messages');
    return (response.data['messages'] as List<dynamic>)
        .map((e) => EmergencyMessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(int emergencyId, String message) async {
    await _dio.post(
      '/api/citizen/emergencies/$emergencyId/messages',
      data: {'message': message},
    );
  }

  Future<void> uploadEvidence(int emergencyId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    await _dio.post('/api/citizen/emergencies/$emergencyId/evidence', data: formData);
  }
}
