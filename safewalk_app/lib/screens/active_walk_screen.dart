import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/map_pin.dart';
import '../widgets/sos_safe_buttons.dart';
import 'chat_screen.dart';
import 'confirm_screen.dart';
import 'ehailing_screen.dart';

class ActiveWalkScreen extends StatefulWidget {
  const ActiveWalkScreen({super.key, required this.groupId, this.destinationName});

  final String groupId;
  final String? destinationName;

  @override
  State<ActiveWalkScreen> createState() => _ActiveWalkScreenState();
}

class _ActiveWalkScreenState extends State<ActiveWalkScreen> {
  List<GroupMemberModel> _members = [];
  Timer? _locationTimer;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
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
    try {
      final res = await Api.getGroup(widget.groupId);
      final members = (res['members'] as List)
          .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _members = members);
    } on ApiException {
      // Roster stays empty if the fetch fails; SOS / chat / safe check-in still work.
    }
  }

  Future<void> _shareLocation() async {
    final (lat, lng) = await LocationService.getCurrent();
    try {
      await Api.postGroupLocation(widget.groupId, lat, lng);
    } on ApiException {
      // Non-fatal: live location just won't update this tick.
    }
  }

  Future<void> _sendSos(BuildContext context) async {
    final (lat, lng) = await LocationService.getCurrent();
    String message = 'Your Guardian Angels and walking group have been notified of your location.';
    try {
      final res = await Api.triggerSos(latitude: lat, longitude: lng, groupId: widget.groupId);
      message = res['message'] as String? ?? message;
    } on ApiException catch (e) {
      message = 'Could not reach the server: ${e.message}';
    }
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('SOS alert sent', style: SWText.quicksand(size: 16, color: SWColors.danger)),
        content: Text(message, style: SWText.inter(size: 13, color: SWColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: SWText.quicksand(size: 13, color: SWColors.violet)),
          ),
        ],
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
    final memberNames = _members.isEmpty
        ? ['Finding your group…']
        : _members.map((m) => m.fullName).toList();

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
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.4, -0.4),
                          radius: 0.8,
                          colors: [SWColors.violet.withValues(alpha: 0.10), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.4, 0.2),
                          radius: 0.9,
                          colors: [SWColors.pink.withValues(alpha: 0.08), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(decoration: BoxDecoration(color: SWColors.lavender)),
                  LayoutBuilder(builder: (context, c) {
                    return Stack(
                      children: [
                        Positioned(
                          top: c.maxHeight * 0.18,
                          left: c.maxWidth * 0.38,
                          child: const MapPin(color: SWColors.violet),
                        ),
                        Positioned(
                          top: c.maxHeight * 0.32,
                          left: c.maxWidth * 0.23,
                          child: const MapPin(color: SWColors.pink),
                        ),
                        Positioned(
                          top: c.maxHeight * 0.44,
                          left: c.maxWidth * 0.57,
                          child: const MapPin(color: SWColors.pink),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatScreen(groupId: widget.groupId)),
                ),
                child: Row(
                  children: memberNames
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: SWColors.lavenderCard,
                                border: Border.all(color: SWColors.border),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(m,
                                  style: SWText.inter(size: 10, weight: FontWeight.w600, color: SWColors.ink)),
                            ),
                          ))
                      .toList(),
                ),
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
