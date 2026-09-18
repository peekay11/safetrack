import 'models.dart';

/// Fallback data shown when the backend can't be reached, so the app still
/// looks and feels complete for a demo instead of going blank. Only used
/// for read/display paths — never for safety-critical actions like SOS,
/// "I am safe", or guardian alerts, which always surface real failures.

const mockSystemSender = 'system';

List<GroupSummary> get mockGroupSummaries => [
      GroupSummary(id: 'mock-grp-1', status: 'forming', memberCount: 2, capacity: 6, groupType: 'walk'),
    ];

List<Destination> get mockDestinations => [
      Destination(
        id: 'mock-dest-bree',
        name: 'Bree Taxi Rank',
        category: 'taxi_rank',
        latitude: -26.2003,
        longitude: 28.0385,
        address: 'Lilian Ngoyi St, Johannesburg (demo)',
      ),
      Destination(
        id: 'mock-dest-park',
        name: 'Park Station',
        category: 'station',
        latitude: -26.1966,
        longitude: 28.0416,
        address: 'Rissik St, Braamfontein (demo)',
      ),
      Destination(
        id: 'mock-dest-maponya',
        name: 'Maponya Mall',
        category: 'mall',
        latitude: -26.2625,
        longitude: 27.9015,
        address: 'Chris Hani Rd, Soweto (demo)',
      ),
    ];

List<Guardian> get mockGuardians => [
      Guardian(id: 'mock-ga-thabo', name: 'Thabo', phoneNumber: '+27821110001', relationship: 'Brother', gender: 'male'),
      Guardian(id: 'mock-ga-zodwa', name: 'Zodwa', phoneNumber: '+27821110002', relationship: 'Aunt', gender: 'female'),
    ];

/// Pickup points are small offsets around the demo Bree Taxi Rank
/// destination so member pins land somewhere sensible on the map.
List<GroupMemberModel> get mockGroupMembers => [
      GroupMemberModel(userId: 'mock-u-lindiwe', fullName: 'Lindiwe', pickupLat: -26.2016, pickupLng: 28.0371),
      GroupMemberModel(userId: 'mock-u-naledi', fullName: 'Naledi', pickupLat: -26.1991, pickupLng: 28.0398),
      GroupMemberModel(userId: 'mock-u-zanele', fullName: 'Zanele', pickupLat: -26.2008, pickupLng: 28.0405),
    ];

List<ChatMessageModel> buildMockChatMessages() => [
      ChatMessageModel(id: 'mock-c1', userId: mockSystemSender, userName: 'System', message: 'Chat opened — 3 members'),
      ChatMessageModel(
        id: 'mock-c2',
        userId: 'mock-u-naledi',
        userName: 'Naledi',
        message: 'Running 5 min late, still coming!',
      ),
      ChatMessageModel(
        id: 'mock-c3',
        userId: 'mock-u-zanele',
        userName: 'Zanele',
        message: 'I see you both, waiting at the corner',
      ),
      ChatMessageModel(id: 'mock-c4', userId: mockSystemSender, userName: 'System', message: 'Zanele checked in as safe ✅'),
    ];

bool isSystemChatMessage(ChatMessageModel m) => m.userId == mockSystemSender;

List<SafetyFlagModel> get mockSafetyFlags => [
      SafetyFlagModel(
        id: 'mock-flag-1',
        latitude: -26.201,
        longitude: 28.040,
        reason: 'poor_lighting',
        severity: 'severe',
        description: 'Streetlights not working under bridge (demo)',
      ),
      SafetyFlagModel(
        id: 'mock-flag-2',
        latitude: -26.199,
        longitude: 28.044,
        reason: 'suspicious_activity',
        severity: 'medium',
        description: 'Loitering reported near alleyway (demo)',
      ),
      SafetyFlagModel(
        id: 'mock-flag-3',
        latitude: -26.203,
        longitude: 28.036,
        reason: 'isolated',
        severity: 'medium',
        description: 'Quiet stretch with few passersby (demo)',
      ),
    ];
