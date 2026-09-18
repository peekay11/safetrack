import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sw_icons.dart';

sealed class _ChatItem {}

class _SystemItem extends _ChatItem {
  _SystemItem(this.text);
  final String text;
}

class _BubbleItem extends _ChatItem {
  _BubbleItem({required this.text, required this.mine, this.name});
  final String text;
  final bool mine;
  final String? name;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatItem> _items = [
    _SystemItem('Chat opened — 3 members'),
    _BubbleItem(name: 'Naledi', text: 'Running 5 min late, still coming!', mine: false),
    _BubbleItem(text: 'On my way to you now 💜', mine: true),
    _BubbleItem(name: 'Zanele', text: 'I see you both, waiting at the corner', mine: false),
    _SystemItem('Zanele checked in as safe ✅'),
  ];

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() => _items.add(_BubbleItem(text: text.trim(), mine: true)));
    _controller.clear();
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
                  Text('Pimville Rank · Group Chat',
                      style: SWText.quicksand(size: 13, color: SWColors.deepPurple)),
                  const SizedBox(height: 2),
                  Text('Active for this walk only',
                      style: SWText.inter(size: 9, color: SWColors.inkSoft)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  if (item is _SystemItem) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: SWColors.deepPurple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(item.text,
                            style: SWText.inter(size: 9, weight: FontWeight.w600, color: SWColors.deepPurple)),
                      ),
                    );
                  }
                  final bubble = item as _BubbleItem;
                  return Align(
                    alignment: bubble.mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: bubble.mine ? SWColors.violet : Colors.white,
                        border: bubble.mine ? null : Border.all(color: SWColors.border),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(bubble.mine ? 14 : 4),
                          bottomRight: Radius.circular(bubble.mine ? 4 : 14),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bubble.name != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(bubble.name!,
                                  style: SWText.inter(size: 8.5, weight: FontWeight.w700, color: SWColors.violet)),
                            ),
                          Text(bubble.text,
                              style: SWText.inter(
                                size: 10.5,
                                height: 1.4,
                                color: bubble.mine ? Colors.white : SWColors.ink,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['Running late', "I've arrived", 'Need help']
                    .map((label) => GestureDetector(
                          onTap: () => _send(label),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: SWColors.lavenderCard,
                              border: Border.all(color: SWColors.border),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(label,
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
        ),
      ),
    );
  }
}
