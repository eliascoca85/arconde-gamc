import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../dtos/emergency_number_dto.dart';

class EmergencyNumbersRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<EmergencyNumberDto>> list() async {
    final response = await _dio.get('/api/citizen/emergency-numbers');
    return (response.data['institutions'] as List<dynamic>)
        .map((e) => EmergencyNumberDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
