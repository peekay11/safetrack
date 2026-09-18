import 'package:flutter/material.dart';
import '../mock_data.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/guardian_alert_dialog.dart';
import '../widgets/offline_banner.dart';
import 'active_walk_screen.dart';

/// Browse groups already heading to a destination and join one, or start a
/// brand-new group of your own — instead of being silently auto-matched.
class GroupListScreen extends StatefulWidget {
  const GroupListScreen({
    super.key,
    required this.destinationId,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
    required this.pickupLat,
    required this.pickupLng,
    this.groupType = 'walk',
    this.taxiPlate,
  });

  final String destinationId;
  final String destinationName;
  final double destinationLat;
  final double destinationLng;
  final double pickupLat;
  final double pickupLng;
  final String groupType;
  final String? taxiPlate;

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  List<GroupSummary>? _groups;
  bool _usingMock = false;
  String? _busyGroupId;
  bool _creating = false;

  bool get _isTaxi => widget.groupType == 'taxi';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _groups = null;
      _usingMock = false;
    });
    try {
      final groups = await Api.listGroups(
        destinationId: widget.destinationId,
        groupType: widget.groupType,
        taxiPlate: widget.taxiPlate,
      );
      if (!mounted) return;
      setState(() => _groups = groups);
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _groups = _isTaxi ? [] : mockGroupSummaries;
        _usingMock = true;
      });
    }
  }

  void _enterActiveWalk(Map<String, dynamic> res) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActiveWalkScreen(
          groupId: res['group_id'] as String,
          destinationName: widget.destinationName,
          destinationLat: widget.destinationLat,
          destinationLng: widget.destinationLng,
        ),
      ),
    );
  }

  Future<void> _join(GroupSummary group) async {
    if (group.id.startsWith('mock-')) {
      _enterActiveWalk({'group_id': group.id});
      return;
    }
    setState(() => _busyGroupId = group.id);
    try {
      final res = await Api.joinGroup(group.id, widget.pickupLat, widget.pickupLng);
      if (res['fallback_to_guardian'] == true && mounted) {
        await showGuardianAlertDialog(context, isTaxi: _isTaxi, notification: res['guardian_notification']);
      }
      if (!mounted) return;
      _enterActiveWalk(res);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _busyGroupId = null);
    }
  }

  Future<void> _createGroup() async {
    setState(() => _creating = true);
    try {
      final res = await Api.createGroup(
        destinationId: widget.destinationId,
        latitude: widget.pickupLat,
        longitude: widget.pickupLng,
        groupType: widget.groupType,
        taxiPlate: widget.taxiPlate,
      );
      if (res['fallback_to_guardian'] == true && mounted) {
        await showGuardianAlertDialog(context, isTaxi: _isTaxi, notification: res['guardian_notification']);
      }
      if (!mounted) return;
      _enterActiveWalk(res);
    } on ApiException {
      // Backend unreachable — fall back to a local demo group like the
      // rest of the app does when offline.
      if (!mounted) return;
      _enterActiveWalk({'group_id': 'mock-group-${widget.destinationId}-${widget.groupType}'});
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SWColors.pageBg,
      appBar: AppBar(
        backgroundColor: SWColors.pageBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: SWColors.deepPurple),
        title: Text('Groups → ${widget.destinationName}',
            style: SWText.quicksand(size: 14, color: SWColors.deepPurple), overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        top: false,
        child: _groups == null
            ? const Center(child: CircularProgressIndicator(color: SWColors.violet))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  if (_usingMock) OfflineBanner(onRetry: _load),
                  GestureDetector(
                    onTap: _creating ? null : _createGroup,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [SWColors.violet, SWColors.deepPurple]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Create a new ${_isTaxi ? 'taxi' : 'walking'} group',
                                    style: SWText.quicksand(size: 13, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text('Be the first — others can join you',
                                    style: SWText.inter(size: 9.5, color: Colors.white.withValues(alpha: 0.9))),
                              ],
                            ),
                          ),
                          if (_creating)
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    _groups!.isEmpty
                        ? 'No open groups heading here yet.'
                        : '${_groups!.length} group${_groups!.length == 1 ? '' : 's'} heading here now',
                    style: SWText.inter(size: 11, color: SWColors.inkSoft),
                  ),
                  const SizedBox(height: 10),
                  for (final g in _groups!) _GroupCard(group: g, busy: _busyGroupId == g.id, onJoin: () => _join(g)),
                ],
              ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.busy, required this.onJoin});
  final GroupSummary group;
  final bool busy;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final full = group.memberCount >= group.capacity;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SWColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: SWColors.lavender, borderRadius: BorderRadius.circular(10)),
            child: Text('${group.memberCount}',
                style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.groupType == 'taxi' && group.taxiPlate != null
                      ? 'Taxi · ${group.taxiPlate}'
                      : 'Walking group',
                  style: SWText.inter(size: 12, weight: FontWeight.w700, color: SWColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.memberCount}/${group.capacity} people · ${group.status == 'active' ? 'Confirmed' : 'Forming'}',
                  style: SWText.inter(size: 10, color: SWColors.inkSoft),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SWColors.violet))
          else
            Material(
              color: full ? SWColors.lavenderMid : SWColors.violet,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: full ? null : onJoin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    full ? 'Full' : 'Join',
                    style: SWText.inter(size: 11, weight: FontWeight.w700, color: full ? SWColors.inkSoft : Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
