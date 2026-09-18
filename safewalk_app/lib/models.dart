bool _asBool(dynamic v) => v == 1 || v == true;
double _asDouble(dynamic v) => (v as num).toDouble();

class SWUser {
  SWUser({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.verified = false,
    this.selfieUrl,
    this.idDocUrl,
    this.language = 'en',
    this.needsExtraTime = false,
  });

  final String id;
  final String phoneNumber;
  final String fullName;
  final bool verified;
  final String? selfieUrl;
  final String? idDocUrl;
  final String language;
  final bool needsExtraTime;

  factory SWUser.fromJson(Map<String, dynamic> json) => SWUser(
        id: json['id'] as String,
        phoneNumber: json['phone_number'] as String? ?? '',
        fullName: json['full_name'] as String? ?? 'SafeWalk User',
        verified: _asBool(json['verified']),
        selfieUrl: json['selfie_url'] as String?,
        idDocUrl: json['id_doc_url'] as String?,
        language: json['language'] as String? ?? 'en',
        needsExtraTime: _asBool(json['needs_extra_time']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'full_name': fullName,
        'verified': verified,
        'selfie_url': selfieUrl,
        'id_doc_url': idDocUrl,
        'language': language,
        'needs_extra_time': needsExtraTime,
      };
}

class Guardian {
  Guardian({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship,
    this.gender,
    this.nightOnly = false,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String? relationship;
  final String? gender;
  final bool nightOnly;

  factory Guardian.fromJson(Map<String, dynamic> json) => Guardian(
        id: json['id'] as String,
        name: json['name'] as String,
        phoneNumber: json['phone_number'] as String? ?? '',
        relationship: json['relationship'] as String?,
        gender: json['gender'] as String?,
        nightOnly: _asBool(json['night_only']),
      );
}

class Destination {
  Destination({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? address;

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        latitude: _asDouble(json['latitude']),
        longitude: _asDouble(json['longitude']),
        address: json['address'] as String?,
      );
}

/// A destination the user is about to match into a group for — either one
/// picked from the preset list, or one they entered themselves (name +
/// a point dropped on the map).
class SelectedDestination {
  SelectedDestination.preset(Destination d)
      : id = d.id,
        name = d.name,
        latitude = d.latitude,
        longitude = d.longitude,
        address = d.address,
        isCustom = false;

  const SelectedDestination.custom({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  })  : id = null,
        isCustom = true;

  final String? id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final bool isCustom;
}

class GroupMemberModel {
  GroupMemberModel({
    required this.userId,
    required this.fullName,
    this.safeCheckedIn = false,
    this.pickupLat,
    this.pickupLng,
    this.selfieUrl,
    this.verified = false,
  });

  final String userId;
  final String fullName;
  final bool safeCheckedIn;
  final double? pickupLat;
  final double? pickupLng;
  final String? selfieUrl;
  final bool verified;

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) => GroupMemberModel(
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String? ?? 'Member',
        safeCheckedIn: _asBool(json['safe_checked_in']),
        pickupLat: json['pickup_lat'] == null ? null : _asDouble(json['pickup_lat']),
        pickupLng: json['pickup_lng'] == null ? null : _asDouble(json['pickup_lng']),
        selfieUrl: json['selfie_url'] as String?,
        verified: _asBool(json['verified']),
      );
}

class ChatMessageModel {
  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    this.quickAction,
  });

  final String id;
  final String userId;
  final String userName;
  final String message;
  final String? quickAction;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        userName: json['user_name'] as String? ?? 'Member',
        message: json['message'] as String,
        quickAction: json['quick_action'] as String?,
      );
}

class SafetyFlagModel {
  SafetyFlagModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.reason,
    required this.severity,
    this.description,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String reason;
  final String severity;
  final String? description;

  factory SafetyFlagModel.fromJson(Map<String, dynamic> json) => SafetyFlagModel(
        id: json['id'] as String,
        latitude: _asDouble(json['latitude']),
        longitude: _asDouble(json['longitude']),
        reason: json['reason'] as String,
        severity: json['severity'] as String? ?? 'medium',
        description: json['description'] as String?,
      );
}
