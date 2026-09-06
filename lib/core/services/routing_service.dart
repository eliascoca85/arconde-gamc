import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Calcula rutas siguiendo calles reales usando el servidor público de OSRM
/// (Open Source Routing Machine), el mismo proyecto que provee las tiles de
/// OpenStreetMap que ya usa la app.
class RoutingService {
  static final Dio _dio = Dio();

  static Future<List<LatLng>?> fetchRoute(LatLng origin, LatLng destination) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';
      final response = await _dio.get(url);
      final routes = response.data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final geometry = routes.first['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      return coordinates
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
