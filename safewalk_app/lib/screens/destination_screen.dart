import 'package:flutter/material.dart';
import '../mock_data.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/offline_banner.dart';
import 'active_walk_screen.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  List<Destination>? _destinations;
  bool _usingMock = false;
  String? _matchingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _destinations = null;
      _usingMock = false;
    });
    try {
      final destinations = await Api.listDestinations();
      if (!mounted) return;
      setState(() => _destinations = destinations);
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _destinations = mockDestinations;
        _usingMock = true;
      });
    }
  }

  Future<void> _match(Destination destination) async {
    setState(() => _matchingId = destination.id);
    final isMockDestination = destination.id.startsWith('mock-');
    try {
      if (isMockDestination) throw ApiException('offline demo destination');
      final (lat, lng) = await LocationService.getCurrent();
      final res = await Api.matchGroup(
        destinationId: destination.id,
        latitude: lat,
        longitude: lng,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActiveWalkScreen(
            groupId: res['group_id'] as String,
            destinationName: destination.name,
            destinationLat: destination.latitude,
            destinationLng: destination.longitude,
          ),
        ),
      );
    } on ApiException {
      // Backend unreachable (or this is already an offline-demo destination) —
      // still let the user walk through the experience with a demo group.
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActiveWalkScreen(
            groupId: 'mock-group-${destination.id}',
            destinationName: destination.name,
            destinationLat: destination.latitude,
            destinationLng: destination.longitude,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _matchingId = null);
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
        title: Text('Find a Group', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_destinations == null) {
      return const Center(child: CircularProgressIndicator(color: SWColors.violet));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        if (_usingMock) OfflineBanner(onRetry: _load),
        Text(
          'Pick where you’re headed — we’ll match you with others walking the same way.',
          style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.6),
        ),
        const SizedBox(height: 14),
        for (final d in _destinations!)
          GestureDetector(
            onTap: _matchingId != null ? null : () => _match(d),
            child: Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: SWText.inter(size: 12, weight: FontWeight.w700, color: SWColors.ink)),
                        const SizedBox(height: 2),
                        Text(
                          [d.category, if (d.address != null) d.address!].join(' · '),
                          style: SWText.inter(size: 10, color: SWColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  if (_matchingId == d.id)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: SWColors.violet),
                    )
                  else
                    const Icon(Icons.chevron_right, color: SWColors.violet),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
