import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sw_icons.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _closed = false;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final res = await Api.getMessages(widget.groupId);
      final messages = (res['messages'] as List)
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _closed = res['is_closed'] == true;
        _loading = false;
      });
      _scrollToBottom();
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text, {String quickAction = 'custom'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _closed) return;
    _controller.clear();
    try {
      await Api.sendMessage(widget.groupId, trimmed, quickAction: quickAction);
      await _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = AppSession.instance.currentUser?.id;

    return Scaffold(
      backgroundColor: SWColors.lavender,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: SWColors.border)),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: SWColors.deepPurple),
                    ),
                  ),
                  Text('Group Chat', style: SWText.quicksand(size: 13, color: SWColors.deepPurple)),
                  const SizedBox(height: 2),
                  Text(_closed ? 'Walk completed — chat closed' : 'Active for this walk only',
                      style: SWText.inter(size: 9, color: SWColors.inkSoft)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: SWColors.violet))
                  : _messages.isEmpty
                      ? Center(
                          child: Text('No messages yet — say hi to your group',
                              style: SWText.inter(size: 11, color: SWColors.inkSoft)),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final msg = _messages[i];
                            final mine = msg.userId == myUserId;
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                decoration: BoxDecoration(
                                  color: mine ? SWColors.violet : Colors.white,
                                  border: mine ? null : Border.all(color: SWColors.border),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(14),
                                    topRight: const Radius.circular(14),
                                    bottomLeft: Radius.circular(mine ? 14 : 4),
                                    bottomRight: Radius.circular(mine ? 4 : 14),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!mine)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(msg.userName,
                                            style: SWText.inter(size: 8.5, weight: FontWeight.w700, color: SWColors.violet)),
                                      ),
                                    Text(msg.message,
                                        style: SWText.inter(
                                          size: 10.5,
                                          height: 1.4,
                                          color: mine ? Colors.white : SWColors.ink,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (!_closed) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    ('Running late', 'running_late'),
                    ("I've arrived", 'arrived'),
                    ('Need help', 'need_help'),
                  ]
                      .map((entry) => GestureDetector(
                            onTap: () => _send(entry.$1, quickAction: entry.$2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: SWColors.lavenderCard,
                                border: Border.all(color: SWColors.border),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(entry.$1,
                                  style: SWText.inter(size: 9.5, weight: FontWeight.w600, color: SWColors.deepPurple)),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: SWColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: SWColors.lavenderCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: _send,
                          style: SWText.inter(size: 10.5, color: SWColors.ink),
                          decoration: InputDecoration(
                            hintText: 'Type a message…',
                            hintStyle: SWText.inter(size: 10.5, color: SWColors.inkSoft),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _send(_controller.text),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: SWColors.violet, shape: BoxShape.circle),
                        child: SWIcons.send(size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
