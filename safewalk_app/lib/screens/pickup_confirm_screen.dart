import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/osm_map.dart';
import 'active_walk_screen.dart';

/// Last step before matching: shows the pickup point on a real map (where
/// the app thinks the user is right now) and lets them tap to correct it,
/// then calls /api/groups/match with the chosen destination + mode.
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
  bool _matching = false;
  String? _error;

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

  Future<void> _confirm() async {
    if (_lat == null || _lng == null) return;
    setState(() {
      _matching = true;
      _error = null;
    });

    final d = widget.destination;
    final destinationIsMock = d.id != null && d.id!.startsWith('mock-');

    try {
      if (destinationIsMock) throw ApiException('offline demo destination');

      final res = await Api.matchGroup(
        destinationId: d.isCustom ? null : d.id,
        customDestinationName: d.isCustom ? d.name : null,
        customDestinationLat: d.isCustom ? d.latitude : null,
        customDestinationLng: d.isCustom ? d.longitude : null,
        customDestinationAddress: d.isCustom ? d.address : null,
        latitude: _lat!,
        longitude: _lng!,
        groupType: widget.groupType,
        taxiPlate: widget.taxiPlate,
      );

      if (res['fallback_to_guardian'] == true && mounted) {
        await _showGuardianAlertDialog(res['guardian_notification'] as Map<String, dynamic>?);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActiveWalkScreen(
            groupId: res['group_id'] as String,
            destinationName: d.name,
            destinationLat: d.latitude,
            destinationLng: d.longitude,
          ),
        ),
      );
    } on ApiException {
      // Backend unreachable (or this destination is already an offline
      // demo) — still let the user walk through the experience.
      if (!mounted) return;
      final key = d.isCustom ? 'custom-${d.name}' : (d.id ?? 'unknown');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActiveWalkScreen(
            groupId: 'mock-group-$key-${widget.groupType}',
            destinationName: d.name,
            destinationLat: d.latitude,
            destinationLng: d.longitude,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _matching = false);
    }
  }

  Future<void> _showGuardianAlertDialog(Map<String, dynamic>? notification) async {
    final guardians = ((notification?['notified_guardians'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Guardian Angel alerted', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guardians.isEmpty
                  ? "We couldn't find a ${_isTaxi ? 'taxi' : 'walking'} group yet, so we've sent your drop-off point via SMS/WhatsApp — but you don't have a Guardian Angel saved to receive it."
                  : "We couldn't find a ${_isTaxi ? 'taxi' : 'walking'} group yet, so we've sent your drop-off point via SMS/WhatsApp to:",
              style: SWText.inter(size: 12, color: SWColors.inkSoft, height: 1.5),
            ),
            for (final g in guardians)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: SWColors.safe),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${g['name']} · ${g['phone_number']}',
                          style: SWText.inter(size: 11, weight: FontWeight.w600, color: SWColors.ink)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK, continue', style: SWText.quicksand(size: 13, color: SWColors.violet)),
          ),
        ],
      ),
    );
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
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Text(_error!, style: SWText.inter(size: 11, color: SWColors.danger)),
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
                    onTap: (_matching || _lat == null) ? null : _confirm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _matching
                          ? const Center(
                              child: SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : Text(
                              'Confirm Pickup & Find Group',
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
