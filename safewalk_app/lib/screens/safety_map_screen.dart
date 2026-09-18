import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../mock_data.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/offline_banner.dart';
import '../widgets/osm_map.dart';

const _reasons = [
  ('poor_lighting', 'Poor lighting'),
  ('harassment', 'Harassment'),
  ('isolated', 'Isolated area'),
  ('suspicious_activity', 'Suspicious activity'),
  ('other', 'Other'),
];

Color _severityColor(String severity) {
  switch (severity) {
    case 'severe':
    case 'high':
      return SWColors.danger;
    case 'medium':
      return SWColors.orange;
    default:
      return SWColors.safe;
  }
}

class SafetyMapScreen extends StatefulWidget {
  const SafetyMapScreen({super.key});

  @override
  State<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends State<SafetyMapScreen> {
  List<SafetyFlagModel> _flags = [];
  bool _loading = true;
  bool _usingMock = false;
  double? _lat;
  double? _lng;
  bool _dropping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (lat, lng) = await LocationService.getCurrent();
    _lat = lat;
    _lng = lng;
    try {
      final flags = await Api.getSafetyFlags(latitude: lat, longitude: lng);
      if (!mounted) return;
      setState(() {
        _flags = flags;
        _usingMock = false;
        _loading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _flags = mockSafetyFlags;
        _usingMock = true;
        _loading = false;
      });
    }
  }

  void _showFlagDetails(SafetyFlagModel flag) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _severityColor(flag.severity)),
                ),
                const SizedBox(width: 8),
                Text(flag.reason.replaceAll('_', ' '),
                    style: SWText.quicksand(size: 14, color: SWColors.deepPurple)),
              ],
            ),
            if (flag.description != null && flag.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(flag.description!, style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.5)),
            ],
            const SizedBox(height: 4),
            Text('Severity: ${flag.severity}', style: SWText.inter(size: 10, color: SWColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Future<void> _dropFlag() async {
    if (_lat == null || _lng == null) return;
    String reason = _reasons.first.$1;
    String severity = 'medium';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Flag this area', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: _reasons
                    .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                    .toList(),
                onChanged: (v) => setDialogState(() => reason = v ?? reason),
              ),
              DropdownButtonFormField<String>(
                initialValue: severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'severe', child: Text('Severe')),
                ],
                onChanged: (v) => setDialogState(() => severity = v ?? severity),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Drop Pin', style: SWText.quicksand(size: 13, color: SWColors.violet)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _dropping = true);
    try {
      await Api.dropSafetyFlag(
        latitude: _lat!,
        longitude: _lng!,
        reason: reason,
        severity: severity,
      );
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _dropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final severe = _flags.where((f) => f.severity == 'severe' || f.severity == 'high').length;
    final medium = _flags.where((f) => f.severity == 'medium').length;
    final low = _flags.length - severe - medium;

    return Scaffold(
      backgroundColor: SWColors.lavender,
      appBar: AppBar(
        backgroundColor: SWColors.lavender,
        elevation: 0,
        iconTheme: const IconThemeData(color: SWColors.deepPurple),
        title: Text('Safety Map', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: SWColors.violet,
        onPressed: _dropping ? null : _dropFlag,
        child: _dropping
            ? const SizedBox(
                height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_location_alt, color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: _loading || _lat == null || _lng == null
            ? const Center(child: CircularProgressIndicator(color: SWColors.violet))
            : Column(
                children: [
                  if (_usingMock)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: OfflineBanner(onRetry: _load),
                    ),
                  Expanded(
                    child: SafeWalkMap(
                      center: LatLng(_lat!, _lng!),
                      zoom: 14,
                      markers: [
                        pinMarker(point: LatLng(_lat!, _lng!), color: SWColors.violet, size: 26),
                        for (final flag in _flags)
                          pinMarker(
                            point: LatLng(flag.latitude, flag.longitude),
                            color: _severityColor(flag.severity),
                            onTap: () => _showFlagDetails(flag),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Legend(color: SWColors.danger, label: 'Red · $severe'),
                        const SizedBox(width: 16),
                        _Legend(color: SWColors.orange, label: 'Orange · $medium'),
                        const SizedBox(width: 16),
                        _Legend(color: SWColors.safe, label: 'Clear · $low'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: SWText.inter(size: 10, weight: FontWeight.w600, color: SWColors.inkSoft)),
      ],
    );
  }
}
