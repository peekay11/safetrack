import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/glass_card.dart';
import '../widgets/sw_icons.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _error;
  String? _devOtpHint;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _devOtpHint = res['dev_otp'] as String?;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.verifyOtp(phone, code, fullName: _nameCtrl.text.trim());
      final token = res['token'] as String;
      final user = res['user'] as Map<String, dynamic>;
      await AppSession.instance.signIn(token: token, userJson: user);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SWColors.lavenderMid,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5],
            colors: [SWColors.deepPurple, SWColors.lavenderMid],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SWIcons.heart(colorHex: '#ffffff', size: 46),
                  const SizedBox(height: 10),
                  Text('SafeWalk', style: SWText.quicksand(size: 20, color: Colors.white)),
                  const SizedBox(height: 24),
                  GlassCard(
                    opacity: 0.85,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _codeSent ? 'Enter your code' : 'Sign in with your phone',
                          style: SWText.quicksand(size: 15, color: SWColors.deepPurple),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _codeSent
                              ? 'We sent a 6-digit code to ${_phoneCtrl.text.trim()}'
                              : "We'll text you a one-time code to verify it's you.",
                          style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        if (!_codeSent) ...[
                          _field(controller: _phoneCtrl, hint: '+27 82 000 0000', keyboardType: TextInputType.phone),
                          const SizedBox(height: 10),
                          _field(controller: _nameCtrl, hint: 'Full name (first time only)'),
                        ] else ...[
                          _field(
                            controller: _codeCtrl,
                            hint: '6-digit code',
                            keyboardType: TextInputType.number,
                          ),
                          if (_devOtpHint != null) ...[
                            const SizedBox(height: 6),
                            Text('Dev OTP: $_devOtpHint',
                                style: SWText.inter(size: 10, color: SWColors.inkSoft)),
                          ],
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: SWText.inter(size: 11, color: SWColors.danger)),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: SWColors.violet,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _loading ? null : (_codeSent ? _verifyOtp : _sendOtp),
                              child: Padding(
                                padding: const EdgeInsets.all(13),
                                child: _loading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        _codeSent ? 'Verify & Continue' : 'Send Code',
                                        textAlign: TextAlign.center,
                                        style: SWText.quicksand(size: 13, color: Colors.white),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        if (_codeSent) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() {
                                      _codeSent = false;
                                      _codeCtrl.clear();
                                      _error = null;
                                    }),
                            child: Text('Change phone number',
                                style: SWText.inter(size: 11, color: SWColors.violet)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: SWText.inter(size: 12, color: SWColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: SWText.inter(size: 12, color: SWColors.inkSoft),
        filled: true,
        fillColor: SWColors.lavender,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
