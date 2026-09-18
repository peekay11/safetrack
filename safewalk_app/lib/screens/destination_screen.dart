import 'package:flutter/material.dart';
import '../mock_data.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/offline_banner.dart';
import 'add_custom_destination_screen.dart';
import 'pickup_confirm_screen.dart';

enum _Mode { walk, taxi }

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  List<Destination>? _destinations;
  bool _usingMock = false;
  _Mode _mode = _Mode.walk;

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

  Future<void> _addCustomDestination() async {
    final picked = await Navigator.of(context).push<SelectedDestination>(
      MaterialPageRoute(builder: (_) => const AddCustomDestinationScreen()),
    );
    if (picked == null || !mounted) return;
    await _proceed(picked);
  }

  Future<void> _pickPreset(Destination d) async {
    await _proceed(SelectedDestination.preset(d));
  }

  Future<void> _proceed(SelectedDestination destination) async {
    if (_mode == _Mode.walk) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PickupConfirmScreen(destination: destination)),
      );
      return;
    }

    // Taxi mode needs the vehicle's number plate to group riders together.
    final plate = await _askForTaxiPlate();
    if (plate == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PickupConfirmScreen(destination: destination, groupType: 'taxi', taxiPlate: plate),
      ),
    );
  }

  Future<String?> _askForTaxiPlate() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Which taxi are you in?', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter the taxi's number plate — we'll group you with everyone else in the same vehicle heading the same way.",
              style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Number plate', hintText: 'e.g. CA 123-456'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final plate = ctrl.text.trim();
              if (plate.length < 3) return;
              Navigator.of(ctx).pop(plate);
            },
            child: Text('Continue', style: SWText.quicksand(size: 13, color: SWColors.violet)),
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
        title: Text('Find a Group', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: _ModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_destinations == null) {
      return const Center(child: CircularProgressIndicator(color: SWColors.violet));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        if (_usingMock) OfflineBanner(onRetry: _load),
        Text(
          _mode == _Mode.walk
              ? 'Pick where you’re headed — we’ll match you with others walking the same way.'
              : 'Pick where the taxi is headed — we’ll group you with everyone else in the same taxi.',
          style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.6),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _addCustomDestination,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: SWColors.lavenderCard,
              border: Border.all(color: SWColors.violet, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_location_alt_rounded, color: SWColors.violet, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Add your own destination',
                      style: SWText.inter(size: 12, weight: FontWeight.w700, color: SWColors.violet)),
                ),
                const Icon(Icons.chevron_right, color: SWColors.violet),
              ],
            ),
          ),
        ),
        for (final d in _destinations!)
          GestureDetector(
            onTap: () => _pickPreset(d),
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
                  const Icon(Icons.chevron_right, color: SWColors.violet),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: SWColors.lavender, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(child: _segment(context, 'Walking Group', Icons.directions_walk, _Mode.walk)),
          Expanded(child: _segment(context, 'Find My Taxi', Icons.local_taxi, _Mode.taxi)),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, IconData icon, _Mode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? SWColors.violet : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : SWColors.inkSoft),
            const SizedBox(width: 6),
            Text(label,
                style: SWText.inter(
                  size: 11,
                  weight: FontWeight.w700,
                  color: selected ? Colors.white : SWColors.inkSoft,
                )),
          ],
        ),
      ),
    );
  }
}
