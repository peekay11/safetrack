import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _selfieTaken = false;
  bool _idUploaded = false;
  final _idNumberCtrl = TextEditingController();

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    super.dispose();
  }

  bool get _complete => _selfieTaken && _idUploaded && _idNumberCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SWColors.pageBg,
      appBar: AppBar(
        backgroundColor: SWColors.pageBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: SWColors.deepPurple),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Text('Verification', style: SWText.quicksand(size: 16, color: SWColors.deepPurple)),
            const SizedBox(height: 12),
            _dashedBox(_selfieTaken ? '✅ Selfie captured' : 'No selfie yet'),
            const SizedBox(height: 12),
            _filledButton('Take Selfie', () => setState(() => _selfieTaken = true)),
            const SizedBox(height: 22),
            Text('ID Document', style: SWText.quicksand(size: 13, color: SWColors.deepPurple)),
            const SizedBox(height: 6),
            Text("SA ID, driver's licence, or passport accepted.",
                style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.6)),
            const SizedBox(height: 10),
            _outlineButton(
              _idUploaded ? 'ID Document uploaded ✅' : 'Upload ID Document',
              () => setState(() => _idUploaded = true),
            ),
            const SizedBox(height: 12),
            Text('ID Number', style: SWText.inter(size: 11, color: SWColors.inkSoft)),
            const SizedBox(height: 6),
            TextField(
              controller: _idNumberCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g. 9001015800082',
                hintStyle: SWText.inter(size: 11, color: SWColors.inkSoft),
                filled: true,
                fillColor: SWColors.lavender,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: SWColors.deepPurple.withValues(alpha: 0.25), style: BorderStyle.solid),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No SA ID? Passport number optional here instead.",
              style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.6).copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _complete ? SWColors.safe.withValues(alpha: 0.15) : SWColors.lavenderMid,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _complete ? '✅ Verification complete' : '⏳ Verification incomplete',
                textAlign: TextAlign.center,
                style: SWText.inter(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _complete ? SWColors.safe : SWColors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashedBox(String label) {
    return Container(
      height: 130,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SWColors.lavender,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SWColors.deepPurple.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Text(label, style: SWText.inter(size: 11, color: SWColors.inkSoft)),
    );
  }

  Widget _filledButton(String label, VoidCallback onTap) {
    return Material(
      color: SWColors.violet,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(label,
              textAlign: TextAlign.center,
              style: SWText.inter(size: 12, weight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: SWColors.violet, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: SWText.inter(size: 12, weight: FontWeight.w700, color: SWColors.violet)),
        ),
      ),
    );
  }
}
