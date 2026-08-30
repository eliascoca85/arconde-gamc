import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../dtos/citizen_dto.dart';

class CitizenRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<CitizenDto> getProfile() async {
    final response = await _dio.get('/api/citizen/profile');
    return CitizenDto.fromJson(response.data['citizen'] as Map<String, dynamic>);
  }

  Future<CitizenDto> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? ci,
  }) async {
    final response = await _dio.put(
      '/api/citizen/profile',
      data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (ci != null) 'CI': ci,
      },
    );
    return CitizenDto.fromJson(response.data['citizen'] as Map<String, dynamic>);
  }
}
