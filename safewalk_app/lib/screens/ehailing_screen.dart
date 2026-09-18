import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sos_safe_buttons.dart';
import 'confirm_screen.dart';

const _providers = ['Uber', 'Bolt', 'InDrive', 'Other'];

class EhailingScreen extends StatefulWidget {
  const EhailingScreen({super.key});

  @override
  State<EhailingScreen> createState() => _EhailingScreenState();
}

class _EhailingScreenState extends State<EhailingScreen> {
  final _driverCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  String _provider = _providers.first;

  bool _starting = false;
  bool _ending = false;
  String? _error;

  String? _tripId;
  bool _blacklystFlagged = false;
  String? _blacklystDetails;
  int _notifiedGuardians = 0;
  Timer? _locationTimer;

  @override
  void dispose() {
    _locationTimer?.cancel();
    _driverCtrl.dispose();
    _regCtrl.dispose();
    super.dispose();
  }

  Future<void> _startTrip() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final (lat, lng) = await LocationService.getCurrent();
      final res = await Api.startEhailing(
        driverName: _driverCtrl.text.trim(),
        vehicleRegistration: _regCtrl.text.trim(),
        serviceProvider: _provider,
        startLat: lat,
        startLng: lng,
      );
      if (!mounted) return;
      setState(() {
        _tripId = res['trip_id'] as String;
        final blacklyst = res['blacklyst'] as Map<String, dynamic>;
        _blacklystFlagged = blacklyst['flagged'] == true;
        _blacklystDetails = blacklyst['details'] as String?;
        _notifiedGuardians = (res['notified_guardians_count'] as num?)?.toInt() ?? 0;
      });
      _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) => _shareLocation());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _shareLocation() async {
    if (_tripId == null) return;
    final (lat, lng) = await LocationService.getCurrent();
    try {
      await Api.postEhailingLocation(_tripId!, lat, lng);
    } on ApiException {
      // Non-fatal — retried on next tick.
    }
  }

  Future<void> _sos() async {
    final (lat, lng) = await LocationService.getCurrent();
    String message = 'SOS alert sent to your Guardian Angels.';
    try {
      final res = await Api.triggerSos(latitude: lat, longitude: lng, ehailingTripId: _tripId);
      message = res['message'] as String? ?? message;
    } on ApiException catch (e) {
      message = 'Could not reach the server: ${e.message}';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _endTrip() async {
    setState(() => _ending = true);
    try {
      if (_tripId != null) await Api.checkinSafeEhailing(_tripId!);
    } on ApiException {
      // Still take the user to the confirmation screen.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ConfirmScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _tripId != null;

    return Scaffold(
      backgroundColor: SWColors.lavender,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SWColors.violet, SWColors.deepPurple],
                ),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  Text(active ? '🚕 E-Hailing Mode Active' : '🚕 Start E-Hailing Mode',
                      style: SWText.quicksand(size: 13, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    active
                        ? 'Live location sharing with Guardian Angels'
                        : 'We’ll check the vehicle and notify your Guardian Angels',
                    style: SWText.inter(size: 9.5, color: Colors.white.withValues(alpha: 0.9)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.2),
                  radius: 0.9,
                  colors: [SWColors.violet.withValues(alpha: 0.15), SWColors.lavenderCard],
                ),
              ),
              child: Align(
                alignment: const Alignment(0.1, -0.3),
                child: Transform.rotate(
                  angle: -0.785398,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: SWColors.violet,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(7),
                        topRight: Radius.circular(7),
                        bottomRight: Radius.circular(7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: SWColors.border),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: active ? _activeDetails() : _setupForm(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: SWText.inter(size: 11, color: SWColors.danger), textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: active
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SosButton(onTap: _sos, size: 56),
                        SafeButton(
                          label: _ending ? 'Ending…' : 'End Trip',
                          onTap: _ending ? () {} : _endTrip,
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: SWColors.violet,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _starting ? null : _startTrip,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: _starting
                                ? const Center(
                                    child: SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Start Trip & Notify Guardians',
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

  Widget _setupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Service'),
        Wrap(
          spacing: 6,
          children: _providers
              .map((p) => ChoiceChip(
                    label: Text(p, style: SWText.inter(size: 10.5, weight: FontWeight.w600)),
                    selected: _provider == p,
                    selectedColor: SWColors.violet.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _provider = p),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        _label('Driver Name (optional)'),
        _textField(_driverCtrl, 'e.g. Sipho M.'),
        const SizedBox(height: 8),
        _label('Vehicle Registration (optional)'),
        _textField(_regCtrl, 'e.g. CA 123-456'),
      ],
    );
  }

  Widget _activeDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Driver Name'),
        _value(_driverCtrl.text.trim().isEmpty ? 'Not provided' : _driverCtrl.text.trim()),
        _label('Vehicle Registration'),
        _value(_regCtrl.text.trim().isEmpty ? 'Not provided' : _regCtrl.text.trim()),
        _label('Service'),
        _value(_provider),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: (_blacklystFlagged ? SWColors.danger : SWColors.safe).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _blacklystFlagged
                ? '⚠️ ${_blacklystDetails ?? 'BlackLyst warning on this vehicle'}'
                : '✅ No BlackLyst reports found',
            textAlign: TextAlign.center,
            style: SWText.inter(
              size: 9.5,
              weight: FontWeight.w700,
              color: _blacklystFlagged ? SWColors.danger : SWColors.safe,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_notifiedGuardians Guardian Angel${_notifiedGuardians == 1 ? '' : 's'} notified by SMS with your live tracking link.',
          style: SWText.inter(size: 9.5, color: SWColors.inkSoft, height: 1.5),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(text.toUpperCase(),
            style: SWText.inter(size: 9.5, color: SWColors.inkSoft, letterSpacing: 0.4)),
      );

  Widget _value(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: SWText.inter(size: 12, weight: FontWeight.w700, color: SWColors.ink)),
      );

  Widget _textField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: SWText.inter(size: 11, color: SWColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: SWText.inter(size: 11, color: SWColors.inkSoft),
        isDense: true,
        filled: true,
        fillColor: SWColors.lavender,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
