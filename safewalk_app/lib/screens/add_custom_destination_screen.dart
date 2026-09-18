import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/osm_map.dart';

/// Lets the user name their own destination and drop a pin for it on a
/// real map, instead of being limited to the preset list. Pops with a
/// [SelectedDestination] when confirmed.
class AddCustomDestinationScreen extends StatefulWidget {
  const AddCustomDestinationScreen({super.key});

  @override
  State<AddCustomDestinationScreen> createState() => _AddCustomDestinationScreenState();
}

class _AddCustomDestinationScreenState extends State<AddCustomDestinationScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final (lat, lng) = await LocationService.getCurrent();
    if (!mounted) return;
    setState(() {
      _lat = lat;
      _lng = lng;
    });
  }

  bool get _canConfirm => _nameCtrl.text.trim().isNotEmpty && _lat != null && _lng != null;

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      SelectedDestination.custom(
        name: _nameCtrl.text.trim(),
        latitude: _lat!,
        longitude: _lng!,
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
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
        title: Text('Add Your Destination', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    style: SWText.inter(size: 12, color: SWColors.ink),
                    decoration: _fieldDecoration('Destination name', "e.g. Aunt Nomvula's house"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressCtrl,
                    style: SWText.inter(size: 12, color: SWColors.ink),
                    decoration: _fieldDecoration('Address (optional)', 'e.g. 12 Vilakazi St, Orlando West'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Tap the map to drop the pin exactly where you’re headed.',
                    style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.5)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _lat == null || _lng == null
                  ? const Center(child: CircularProgressIndicator(color: SWColors.violet))
                  : SafeWalkMap(
                      center: LatLng(_lat!, _lng!),
                      zoom: 15,
                      onTap: (point) => setState(() {
                        _lat = point.latitude;
                        _lng = point.longitude;
                      }),
                      markers: [
                        pinMarker(point: LatLng(_lat!, _lng!), color: SWColors.pink, size: 36),
                      ],
                    ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: _canConfirm ? SWColors.violet : SWColors.lavenderMid,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _canConfirm ? _confirm : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Use This Destination',
                        textAlign: TextAlign.center,
                        style: SWText.quicksand(size: 13, color: _canConfirm ? Colors.white : SWColors.deepPurple),
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

  InputDecoration _fieldDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: SWText.inter(size: 11, color: SWColors.inkSoft),
      filled: true,
      fillColor: SWColors.lavender,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}
