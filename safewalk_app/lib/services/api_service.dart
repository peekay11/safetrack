import 'dart:typed_data';
import '../models.dart';
import 'api_client.dart';
import 'app_session.dart';

/// Typed calls for every SafeTrack backend route. Uses the shared,
/// session-authenticated [ApiClient] from [AppSession].
class Api {
  Api._();

  static ApiClient get _c => AppSession.instance.client;

  // --- Auth ---------------------------------------------------------

  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) =>
      _c.post('/api/auth/send-otp', {'phone_number': phoneNumber});

  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String code, {
    String? fullName,
  }) =>
      _c.post('/api/auth/verify-otp', {
        'phone_number': phoneNumber,
        'code': code,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      });

  static Future<Map<String, dynamic>> me() => _c.get('/api/auth/me');

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> patch) =>
      _c.patch('/api/auth/profile', patch);

  // --- Guardian Angels ------------------------------------------------

  static Future<List<Guardian>> listGuardians() async {
    final res = await _c.get('/api/guardians');
    return (res['guardians'] as List).map((e) => Guardian.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Guardian> addGuardian({
    required String name,
    required String phoneNumber,
    String? relationship,
    String? gender,
    bool nightOnly = false,
  }) async {
    final res = await _c.post('/api/guardians', {
      'name': name,
      'phone_number': phoneNumber,
      if (relationship != null && relationship.isNotEmpty) 'relationship': relationship,
      if (gender != null) 'gender': gender,
      'night_only': nightOnly,
    });
    return Guardian.fromJson(res['guardian'] as Map<String, dynamic>);
  }

  static Future<void> removeGuardian(String id) => _c.delete('/api/guardians/$id');

  // --- Groups / Walking Together --------------------------------------

  static Future<List<Destination>> listDestinations() async {
    final res = await _c.get('/api/groups/destinations');
    return (res['destinations'] as List)
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> matchGroup({
    required String destinationId,
    required double latitude,
    required double longitude,
  }) =>
      _c.post('/api/groups/match', {
        'destination_id': destinationId,
        'latitude': latitude,
        'longitude': longitude,
      });

  static Future<Map<String, dynamic>> getGroup(String groupId) => _c.get('/api/groups/$groupId');

  static Future<void> postGroupLocation(String groupId, double latitude, double longitude) =>
      _c.post('/api/groups/$groupId/location', {'latitude': latitude, 'longitude': longitude});

  static Future<Map<String, dynamic>> getGroupLocations(String groupId) =>
      _c.get('/api/groups/$groupId/locations');

  static Future<void> checkpointArrival(String groupId, String targetMemberId) =>
      _c.post('/api/groups/$groupId/checkpoint-arrival', {'target_member_id': targetMemberId});

  static Future<Map<String, dynamic>> checkinSafe(String groupId) =>
      _c.post('/api/groups/$groupId/checkin-safe');

  // --- Active Walk Chat -------------------------------------------------

  static Future<Map<String, dynamic>> getMessages(String groupId) => _c.get('/api/chat/$groupId');

  static Future<Map<String, dynamic>> sendMessage(
    String groupId,
    String message, {
    String quickAction = 'custom',
  }) =>
      _c.post('/api/chat/$groupId', {'message': message, 'quick_action': quickAction});

  static Future<void> flagMessage(String groupId, String messageId) =>
      _c.post('/api/chat/$groupId/messages/$messageId/flag');

  // --- SOS ---------------------------------------------------------------

  static Future<Map<String, dynamic>> triggerSos({
    required double latitude,
    required double longitude,
    String? groupId,
    String? ehailingTripId,
    String triggerType = 'app_sos',
    String? distressMessage,
  }) =>
      _c.post('/api/sos/trigger', {
        'latitude': latitude,
        'longitude': longitude,
        if (groupId != null) 'group_id': groupId,
        if (ehailingTripId != null) 'ehailing_trip_id': ehailingTripId,
        'trigger_type': triggerType,
        if (distressMessage != null) 'distress_message': distressMessage,
      });

  static Future<Map<String, dynamic>> acknowledgeSos(String sosId, String guardianName) =>
      _c.post('/api/sos/$sosId/acknowledge', {'guardian_name': guardianName});

  static Future<Map<String, dynamic>> resolveSos(String sosId, {bool isFalseAlarm = false}) =>
      _c.post('/api/sos/$sosId/resolve', {'is_false_alarm': isFalseAlarm});

  // --- E-Hailing Mode ------------------------------------------------------

  static Future<Map<String, dynamic>> startEhailing({
    String? driverName,
    String? vehicleRegistration,
    String serviceProvider = 'Uber',
    required double startLat,
    required double startLng,
  }) =>
      _c.post('/api/ehailing/start', {
        if (driverName != null && driverName.isNotEmpty) 'driver_name': driverName,
        if (vehicleRegistration != null && vehicleRegistration.isNotEmpty)
          'vehicle_registration': vehicleRegistration,
        'service_provider': serviceProvider,
        'start_lat': startLat,
        'start_lng': startLng,
      });

  static Future<void> postEhailingLocation(String tripId, double latitude, double longitude) =>
      _c.post('/api/ehailing/$tripId/location', {'latitude': latitude, 'longitude': longitude});

  static Future<Map<String, dynamic>> checkinSafeEhailing(String tripId) =>
      _c.post('/api/ehailing/$tripId/checkin-safe');

  // --- Safety Map ------------------------------------------------------------

  static Future<List<SafetyFlagModel>> getSafetyFlags({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final res = await _c.get('/api/safety-map/flags', query: {
      'lat': latitude,
      'lng': longitude,
      'radius': radiusKm,
    });
    return (res['flags'] as List)
        .map((e) => SafetyFlagModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<SafetyFlagModel> dropSafetyFlag({
    required double latitude,
    required double longitude,
    required String reason,
    String severity = 'medium',
    String? description,
  }) async {
    final res = await _c.post('/api/safety-map/flags', {
      'latitude': latitude,
      'longitude': longitude,
      'reason': reason,
      'severity': severity,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return SafetyFlagModel.fromJson(res['flag'] as Map<String, dynamic>);
  }

  // --- Verification --------------------------------------------------------

  static Future<Map<String, dynamic>> uploadSelfie(Uint8List bytes, String filename) =>
      _c.uploadFile('/api/verification/selfie', fieldName: 'file', bytes: bytes, filename: filename);

  static Future<Map<String, dynamic>> uploadIdDocument(
    Uint8List bytes,
    String filename, {
    String? idNumber,
    String idType = 'sa_id',
  }) =>
      _c.uploadFile(
        '/api/verification/id-document',
        fieldName: 'file',
        bytes: bytes,
        filename: filename,
        fields: {
          'id_type': idType,
          if (idNumber != null && idNumber.isNotEmpty) 'id_number': idNumber,
        },
      );
}
