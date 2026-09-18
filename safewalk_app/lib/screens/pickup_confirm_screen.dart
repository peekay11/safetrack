import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/guardian_alert_dialog.dart';
import '../widgets/osm_map.dart';
import 'active_walk_screen.dart';
import 'destination_insights_screen.dart';
import 'group_list_screen.dart';

/// Last step before matching: shows the pickup point on a real map (where
/// the app thinks the user is right now) and lets them tap to correct it.
/// A preset destination goes on to browse/join/create a group; a
/// user-entered custom destination — where no one else could possibly be
/// going yet — creates a fresh group directly.
class PickupConfirmScreen extends StatefulWidget {
  const PickupConfirmScreen({
    super.key,
    required this.destination,
    this.groupType = 'walk',
    this.taxiPlate,
  });

  final SelectedDestination destination;
  final String groupType;
  final String? taxiPlate;

  @override
  State<PickupConfirmScreen> createState() => _PickupConfirmScreenState();
}

class _PickupConfirmScreenState extends State<PickupConfirmScreen> {
  double? _lat;
  double? _lng;
  bool _busy = false;

  bool get _isTaxi => widget.groupType == 'taxi';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final (lat, lng) = await LocationService.getCurrent();
    if (!mounted) return;
    setState(() {
      _lat = lat;
      _lng = lng;
    });
  }

  void _enterActiveWalk(String groupId) {
    final d = widget.destination;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActiveWalkScreen(
          groupId: groupId,
          destinationName: d.name,
          destinationLat: d.latitude,
          destinationLng: d.longitude,
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_lat == null || _lng == null) return;
    setState(() => _busy = true);

    final d = widget.destination;
    final destinationIsMock = d.id != null && d.id!.startsWith('mock-');

    try {
      if (destinationIsMock) throw ApiException('offline demo destination');

      if (d.isCustom) {
        // Nobody else could already be heading to a spot the user just
        // typed themselves — skip browsing and create the group directly.
        final res = await Api.createGroup(
          customDestinationName: d.name,
          customDestinationLat: d.latitude,
          customDestinationLng: d.longitude,
          customDestinationAddress: d.address,
          latitude: _lat!,
          longitude: _lng!,
          groupType: widget.groupType,
          taxiPlate: widget.taxiPlate,
        );
        if (res['fallback_to_guardian'] == true && mounted) {
          await showGuardianAlertDialog(context, isTaxi: _isTaxi, notification: res['guardian_notification']);
        }
        if (!mounted) return;
        _enterActiveWalk(res['group_id'] as String);
        return;
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupListScreen(
            destinationId: d.id!,
            destinationName: d.name,
            destinationLat: d.latitude,
            destinationLng: d.longitude,
            pickupLat: _lat!,
            pickupLng: _lng!,
            groupType: widget.groupType,
            taxiPlate: widget.taxiPlate,
          ),
        ),
      );
    } on ApiException {
      // Backend unreachable (or this destination is already an offline
      // demo) — still let the user walk through the experience.
      if (!mounted) return;
      final key = d.isCustom ? 'custom-${d.name}' : (d.id ?? 'unknown');
      _enterActiveWalk('mock-group-$key-${widget.groupType}');
    } finally {
      if (mounted) setState(() => _busy = false);
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
        title: Text('Confirm Pickup', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DestinationInsightsScreen(destination: widget.destination)),
            ),
            icon: const Icon(Icons.auto_awesome, size: 15, color: SWColors.violet),
            label: Text('Ask AI', style: SWText.inter(size: 11, weight: FontWeight.w700, color: SWColors.violet)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_isTaxi ? Icons.local_taxi : Icons.directions_walk, size: 16, color: SWColors.violet),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('To: ${widget.destination.name}',
                            style: SWText.quicksand(size: 14, color: SWColors.deepPurple),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (_isTaxi && widget.taxiPlate != null) ...[
                    const SizedBox(height: 4),
                    Text('Taxi plate: ${widget.taxiPlate}', style: SWText.inter(size: 11, color: SWColors.inkSoft)),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Tap the map to adjust exactly where you’ll be picked up.',
                    style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _lat == null || _lng == null
                  ? const Center(child: CircularProgressIndicator(color: SWColors.violet))
                  : SafeWalkMap(
                      center: LatLng(_lat!, _lng!),
                      zoom: 16,
                      onTap: (point) => setState(() {
                        _lat = point.latitude;
                        _lng = point.longitude;
                      }),
                      markers: [
                        pinMarker(point: LatLng(_lat!, _lng!), color: SWColors.violet, size: 36),
                        pinMarker(
                          point: LatLng(widget.destination.latitude, widget.destination.longitude),
                          color: SWColors.deepPurple,
                        ),
                      ],
                    ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: SWColors.violet,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: (_busy || _lat == null) ? null : _confirm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _busy
                          ? const Center(
                              child: SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : Text(
                              widget.destination.isCustom ? 'Confirm Pickup & Create Group' : 'Confirm Pickup & Continue',
                              textAlign: TextAlign.center,
                              style: SWText.quicksand(size: 13, color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
