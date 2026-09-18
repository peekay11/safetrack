import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sos_safe_buttons.dart';
import 'confirm_screen.dart';

class EhailingScreen extends StatefulWidget {
  const EhailingScreen({super.key});

  @override
  State<EhailingScreen> createState() => _EhailingScreenState();
}

class _EhailingScreenState extends State<EhailingScreen> {
  bool _checking = false;
  bool _checked = false;

  Future<void> _checkBlackLyst() async {
    setState(() => _checking = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checked = true;
    });
  }

  void _sos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS alert sent to your Guardian Angels.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('🚕 E-Hailing Mode Active',
                      style: SWText.quicksand(size: 13, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Live location sharing with Guardian Angels',
                      style: SWText.inter(size: 9.5, color: Colors.white.withValues(alpha: 0.9))),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Driver Name'),
                        _value('Sipho M.'),
                        _label('Vehicle Registration'),
                        _value('CA 123-456'),
                        const SizedBox(height: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _checking ? null : _checkBlackLyst,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: SWColors.violet, width: 1.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _checking ? 'Checking…' : 'Check BlackLyst',
                                textAlign: TextAlign.center,
                                style: SWText.inter(size: 10.5, weight: FontWeight.w700, color: SWColors.violet),
                              ),
                            ),
                          ),
                        ),
                        if (_checked)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: SWColors.safe.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('✅ No reports found',
                                textAlign: TextAlign.center,
                                style: SWText.inter(size: 9.5, weight: FontWeight.w700, color: SWColors.safe)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SosButton(onTap: _sos, size: 56),
                  SafeButton(
                    label: 'End Trip',
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ConfirmScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}
