import '../../shared/models/availability_model.dart';
import '../../shared/models/parking_space_model.dart';
import '../network/api_client.dart';

class ParkingService {
  ParkingService._();
  static final ParkingService instance = ParkingService._();

  ApiClient get _api => ApiClient.instance;

  Future<List<ParkingSpace>> fetchSpaces() async {
    final res = await _api.get<List<dynamic>>('/api/parking/spaces');
    return (res.data ?? const [])
        .map((e) => ParkingSpace.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Availability of a single space for a specific date based on overlapping
  /// bookings (the backend derives availability server-side).
  Future<Availability> fetchAvailability({
    required String spaceId,
    required String date,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/api/parking/spaces/$spaceId/availability',
      queryParameters: {'date': date},
    );
    return Availability.fromMap(
      Map<String, dynamic>.from(res.data ?? const {}),
    );
  }
}