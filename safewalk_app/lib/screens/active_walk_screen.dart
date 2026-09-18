import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import '../mock_data.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/offline_banner.dart';
import '../widgets/osm_map.dart';
import '../widgets/sos_safe_buttons.dart';
import '../widgets/sw_avatar.dart';
import 'chat_screen.dart';
import 'confirm_screen.dart';
import 'ehailing_screen.dart';

class ActiveWalkScreen extends StatefulWidget {
  const ActiveWalkScreen({
    super.key,
    required this.groupId,
    this.destinationName,
    this.destinationLat,
    this.destinationLng,
  });

  final String groupId;
  final String? destinationName;
  final double? destinationLat;
  final double? destinationLng;

  @override
  State<ActiveWalkScreen> createState() => _ActiveWalkScreenState();
}

class _ActiveWalkScreenState extends State<ActiveWalkScreen> {
  List<GroupMemberModel> _members = [];
  bool _usingMock = false;
  Timer? _locationTimer;
  bool _checkingIn = false;
  double? _myLat;
  double? _myLng;
  double? _destLat;
  double? _destLng;

  bool get _isMockGroup => widget.groupId.startsWith('mock-');

  @override
  void initState() {
    super.initState();
    _destLat = widget.destinationLat;
    _destLng = widget.destinationLng;
    _loadGroup();
    _shareLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) => _shareLocation());
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    if (_isMockGroup) {
      setState(() {
        _members = mockGroupMembers;
        _usingMock = true;
      });
      return;
    }
    try {
      final res = await Api.getGroup(widget.groupId);
      final members = (res['members'] as List)
          .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final destination = res['destination'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _members = members;
        _usingMock = false;
        if (destination != null) {
          _destLat = (destination['latitude'] as num).toDouble();
          _destLng = (destination['longitude'] as num).toDouble();
        }
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _members = mockGroupMembers;
        _usingMock = true;
      });
    }
  }

  Future<void> _shareLocation() async {
    final (lat, lng) = await LocationService.getCurrent();
    if (!mounted) return;
    setState(() {
      _myLat = lat;
      _myLng = lng;
    });
    if (_isMockGroup) return;
    try {
      await Api.postGroupLocation(widget.groupId, lat, lng);
    } on ApiException {
      // Non-fatal: live location just won't update this tick.
    }
  }

  Future<void> _sendSos(BuildContext context) async {
    final (lat, lng) = await LocationService.getCurrent();
    String message = 'Your Guardian Angels and walking group have been notified of your location.';
    String? sosId;
    try {
      final res = await Api.triggerSos(latitude: lat, longitude: lng, groupId: widget.groupId);
      message = res['message'] as String? ?? message;
      sosId = res['sos_id'] as String?;
    } on ApiException catch (e) {
      message = 'Could not reach the server: ${e.message}';
    }
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => _SosAlertDialog(message: message, sosId: sosId),
    );
  }

  void _showMemberProfile(GroupMemberModel m) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SWAvatar(
                name: m.fullName,
                imageUrl: ApiConfig.mediaUrl(m.selfieUrl),
                size: 84,
                verified: m.verified,
              ),
              const SizedBox(height: 14),
              Text(m.fullName, style: SWText.quicksand(size: 17, color: SWColors.deepPurple)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: (m.verified ? SWColors.safe : SWColors.orange).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  m.verified ? '✅ Verified SafeWalk member' : '⏳ Not yet verified',
                  style: SWText.inter(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: m.verified ? SWColors.safe : SWColors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                m.safeCheckedIn ? 'Checked in safe' : 'Currently walking',
                style: SWText.inter(size: 11, color: SWColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkInSafe() async {
    setState(() => _checkingIn = true);
    try {
      await Api.checkinSafe(widget.groupId);
    } on ApiException {
      // Even if the confirmation call fails, still show the confirm screen —
      // the user is telling us they've arrived safely.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ConfirmScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = AppSession.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: SWColors.deepPurple),
                  ),
                  Expanded(
                    child: Text(
                      widget.destinationName ?? 'Active Walk',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: SWText.quicksand(size: 13, color: SWColors.deepPurple),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EhailingScreen()),
                    ),
                    icon: const Icon(Icons.local_taxi, size: 16, color: SWColors.violet),
                    label: Text('E-Hailing', style: SWText.inter(size: 11, weight: FontWeight.w600, color: SWColors.violet)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatScreen(groupId: widget.groupId)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, color: SWColors.violet),
                  ),
                ],
              ),
            ),
            if (_usingMock)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: OfflineBanner(
                  message: "Demo mode — showing a sample walking group.",
                  onRetry: _isMockGroup ? null : _loadGroup,
                ),
              ),
            Expanded(
              child: _myLat == null || _myLng == null
                  ? const Center(child: CircularProgressIndicator(color: SWColors.violet))
                  : SafeWalkMap(
                      center: LatLng(
                        _destLat ?? _myLat!,
                        _destLng ?? _myLng!,
                      ),
                      zoom: 14,
                      markers: [
                        avatarMarker(
                          point: LatLng(_myLat!, _myLng!),
                          name: me?.fullName ?? 'You',
                          imageUrl: ApiConfig.mediaUrl(me?.selfieUrl),
                          ringColor: SWColors.violet,
                          verified: me?.verified ?? false,
                        ),
                        if (_destLat != null && _destLng != null)
                          pinMarker(point: LatLng(_destLat!, _destLng!), color: SWColors.deepPurple, size: 34),
                        for (final m in _members)
                          if (m.pickupLat != null && m.pickupLng != null)
                            avatarMarker(
                              point: LatLng(m.pickupLat!, m.pickupLng!),
                              name: m.fullName,
                              imageUrl: ApiConfig.mediaUrl(m.selfieUrl),
                              verified: m.verified,
                              onTap: () => _showMemberProfile(m),
                            ),
                      ],
                    ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    height: 46,
                    width: _members.isEmpty ? 46 : 46 + (_members.length - 1) * 26.0,
                    child: _members.isEmpty
                        ? const SizedBox(
                            width: 46,
                            height: 46,
                            child: CircularProgressIndicator(strokeWidth: 2, color: SWColors.violet),
                          )
                        : Stack(
                            children: [
                              for (int i = 0; i < _members.length; i++)
                                Positioned(
                                  left: i * 26.0,
                                  child: GestureDetector(
                                    onTap: () => _showMemberProfile(_members[i]),
                                    child: SWAvatar(
                                      name: _members[i].fullName,
                                      imageUrl: ApiConfig.mediaUrl(_members[i].selfieUrl),
                                      size: 40,
                                      verified: _members[i].verified,
                                      ringColor: _members[i].safeCheckedIn ? SWColors.safe : Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChatScreen(groupId: widget.groupId)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _members.isEmpty
                                ? 'Finding your group…'
                                : '${_members.length} walking with you',
                            style: SWText.quicksand(size: 12.5, color: SWColors.deepPurple),
                          ),
                          const SizedBox(height: 2),
                          Text('Tap to open group chat',
                              style: SWText.inter(size: 9.5, color: SWColors.inkSoft)),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.chat_bubble_outline, color: SWColors.violet),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SosButton(onTap: () => _sendSos(context)),
                  SafeButton(
                    label: _checkingIn ? 'Checking in…' : 'I Am Safe',
                    onTap: _checkingIn ? () {} : _checkInSafe,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The post-SOS confirmation dialog, with an optional "record video
/// evidence" step — captured while help is on the way and uploaded to R2,
/// linked to the SOS event.
class _SosAlertDialog extends StatefulWidget {
  const _SosAlertDialog({required this.message, this.sosId});

  final String message;
  final String? sosId;

  @override
  State<_SosAlertDialog> createState() => _SosAlertDialogState();
}

class _SosAlertDialogState extends State<_SosAlertDialog> {
  final _picker = ImagePicker();
  bool _uploading = false;
  bool _uploaded = false;
  String? _error;

  Future<void> _recordVideo() async {
    final sosId = widget.sosId;
    if (sosId == null) return;
    final video = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30));
    if (video == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final bytes = await video.readAsBytes();
      await Api.uploadSosVideo(sosId, bytes, video.name);
      if (!mounted) return;
      setState(() => _uploaded = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('SOS alert sent', style: SWText.quicksand(size: 16, color: SWColors.danger)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: SWText.inter(size: 13, color: SWColors.inkSoft)),
          if (widget.sosId != null) ...[
            const SizedBox(height: 14),
            if (_uploaded)
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: SWColors.safe),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Video evidence attached to this SOS',
                        style: SWText.inter(size: 11, weight: FontWeight.w700, color: SWColors.safe)),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _uploading ? null : _recordVideo,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: SWColors.danger, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _uploading
                          ? const SizedBox(
                              height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: SWColors.danger))
                          : const Icon(Icons.videocam, size: 16, color: SWColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploading ? 'Uploading video…' : 'Record video evidence',
                          style: SWText.inter(size: 11, weight: FontWeight.w700, color: SWColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: SWText.inter(size: 10, color: SWColors.danger)),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK', style: SWText.quicksand(size: 13, color: SWColors.violet)),
        ),
      ],
    );
  }
}
