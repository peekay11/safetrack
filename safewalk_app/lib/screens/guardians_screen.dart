import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class GuardiansScreen extends StatefulWidget {
  const GuardiansScreen({super.key});

  @override
  State<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends State<GuardiansScreen> {
  List<Guardian> _guardians = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final guardians = await Api.listGuardians();
      if (!mounted) return;
      setState(() {
        _guardians = guardians;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _call(Guardian g) async {
    final uri = Uri(scheme: 'tel', path: g.phoneNumber.replaceAll(' ', ''));
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${g.name}…')));
    }
  }

  Future<void> _remove(Guardian g) async {
    try {
      await Api.removeGuardian(g.id);
      if (!mounted) return;
      setState(() => _guardians.removeWhere((x) => x.id == g.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addGuardian() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    String gender = 'female';
    bool nightOnly = false;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Guardian Angel', style: SWText.quicksand(size: 16, color: SWColors.deepPurple)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relation')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setDialogState(() => gender = v ?? gender),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: nightOnly,
                  title: const Text('Night-only alerts'),
                  onChanged: (v) => setDialogState(() => nightOnly = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length < 10) return;
                try {
                  final guardian = await Api.addGuardian(
                    name: nameCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.trim(),
                    relationship: relationCtrl.text.trim(),
                    gender: gender,
                    nightOnly: nightOnly,
                  );
                  if (!mounted) return;
                  setState(() => _guardians.add(guardian));
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } on ApiException catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              child: Text('Add', style: SWText.quicksand(size: 13, color: SWColors.violet)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = _guardians.length < 4;

    return Scaffold(
      backgroundColor: SWColors.pageBg,
      appBar: AppBar(
        backgroundColor: SWColors.pageBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: SWColors.deepPurple),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: SWColors.violet))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  Text('Guardian Angels', style: SWText.quicksand(size: 16, color: SWColors.deepPurple)),
                  const SizedBox(height: 8),
                  Text(
                    'Up to 4 trusted contacts. Specify gender so the app can respect your preferences.',
                    style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!, style: SWText.inter(size: 11, color: SWColors.danger)),
                    const SizedBox(height: 12),
                  ],
                  for (final g in _guardians)
                    Container(
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
                                Text(
                                  g.relationship == null || g.relationship!.isEmpty
                                      ? g.name
                                      : '${g.name} (${g.relationship})',
                                  style: SWText.inter(size: 12, weight: FontWeight.w600, color: SWColors.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(g.gender ?? '', style: SWText.inter(size: 10, color: SWColors.inkSoft)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _call(g),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text('Call',
                                  style: SWText.inter(size: 11, weight: FontWeight.w700, color: SWColors.violet)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _remove(g),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 14),
                              child: Text('Remove',
                                  style: SWText.inter(size: 11, weight: FontWeight.w700, color: SWColors.danger)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: canAddMore ? _addGuardian : null,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: SWColors.violet, width: 1.5, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          canAddMore
                              ? '+ Add Guardian Angel (${_guardians.length}/4)'
                              : 'Guardian Angels full (4/4)',
                          style: SWText.inter(
                            size: 11,
                            weight: FontWeight.w700,
                            color: canAddMore ? SWColors.violet : SWColors.inkSoft,
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
