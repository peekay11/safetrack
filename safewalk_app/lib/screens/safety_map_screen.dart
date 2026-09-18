import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

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
        _loading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
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
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: SWColors.violet))
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-0.5, -0.4),
                                radius: 0.3,
                                colors: [SWColors.danger.withValues(alpha: 0.18), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0.2, 0.1),
                                radius: 0.3,
                                colors: [SWColors.orange.withValues(alpha: 0.18), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        if (_flags.isEmpty)
                          Center(
                            child: Text('No flagged spots nearby right now',
                                style: SWText.inter(size: 11, color: SWColors.inkSoft)),
                          )
                        else
                          ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _flags.length,
                            itemBuilder: (context, i) {
                              final flag = _flags[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: SWColors.border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _severityColor(flag.severity),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(flag.reason.replaceAll('_', ' '),
                                              style: SWText.inter(size: 11, weight: FontWeight.w700, color: SWColors.ink)),
                                          if (flag.description != null && flag.description!.isNotEmpty)
                                            Text(flag.description!,
                                                style: SWText.inter(size: 9.5, color: SWColors.inkSoft)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
