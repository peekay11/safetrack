import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class Guardian {
  Guardian(this.name, this.relation, this.gender);
  final String name;
  final String relation;
  final String gender;
}

class GuardiansScreen extends StatefulWidget {
  const GuardiansScreen({super.key});

  @override
  State<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends State<GuardiansScreen> {
  final List<Guardian> _guardians = [
    Guardian('Thabo', 'Brother', 'Male'),
    Guardian('Zodwa', 'Aunt', 'Female'),
  ];

  void _call(Guardian g) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${g.name}…')),
    );
  }

  Future<void> _addGuardian() async {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    String gender = 'Female';

    final added = await showDialog<Guardian>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Guardian Angel', style: SWText.quicksand(size: 16, color: SWColors.deepPurple)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relation')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const ['Female', 'Male', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setDialogState(() => gender = v ?? gender),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop(
                  Guardian(nameCtrl.text.trim(), relationCtrl.text.trim(), gender),
                );
              },
              child: Text('Add', style: SWText.quicksand(size: 13, color: SWColors.violet)),
            ),
          ],
        ),
      ),
    );

    if (added != null) {
      setState(() => _guardians.add(added));
    }
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Text('Guardian Angels', style: SWText.quicksand(size: 16, color: SWColors.deepPurple)),
            const SizedBox(height: 8),
            Text(
              'Up to 4 trusted contacts. Specify gender so the app can respect your preferences.',
              style: SWText.inter(size: 11, color: SWColors.inkSoft, height: 1.6),
            ),
            const SizedBox(height: 16),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${g.name} (${g.relation})',
                            style: SWText.inter(size: 12, weight: FontWeight.w600, color: SWColors.ink)),
                        const SizedBox(height: 2),
                        Text(g.gender, style: SWText.inter(size: 10, color: SWColors.inkSoft)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _call(g),
                      child: Text('Call',
                          style: SWText.inter(size: 11, weight: FontWeight.w700, color: SWColors.violet)),
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
