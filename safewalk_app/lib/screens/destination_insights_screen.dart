import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class _InsightMessage {
  _InsightMessage({required this.role, required this.content});
  final String role; // 'user' | 'assistant'
  final String content;
}

/// A conversational AI assistant, grounded in SafeTrack's own safety-flag
/// and pickup-activity data, that answers questions about a destination
/// before the user heads there.
class DestinationInsightsScreen extends StatefulWidget {
  const DestinationInsightsScreen({super.key, required this.destination});

  final SelectedDestination destination;

  @override
  State<DestinationInsightsScreen> createState() => _DestinationInsightsScreenState();
}

class _DestinationInsightsScreenState extends State<DestinationInsightsScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_InsightMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _send('Give me a quick safety overview of this place before I head there.', isInitial: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _send(String text, {bool isInitial = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;
    _controller.clear();

    setState(() {
      if (!isInitial) _messages.add(_InsightMessage(role: 'user', content: trimmed));
      _loading = true;
    });
    _scrollToBottom();

    final d = widget.destination;
    try {
      final res = await Api.chatAboutDestination(
        name: d.name,
        category: d.isCustom ? 'custom' : null,
        address: d.address,
        latitude: d.latitude,
        longitude: d.longitude,
        message: trimmed,
        history: _messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_InsightMessage(role: 'assistant', content: res['reply'] as String));
        _loading = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_InsightMessage(
          role: 'assistant',
          content: "I couldn't reach the insights service right now (${e.message}). Please try again in a moment.",
        ));
        _loading = false;
      });
      _scrollToBottom();
    }
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
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [SWColors.violet, SWColors.deepPurple]),
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
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text('SafeWalk AI Insights', style: SWText.quicksand(size: 13, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(widget.destination.name,
                      style: SWText.inter(size: 10, color: Colors.white.withValues(alpha: 0.9)),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: SWColors.violet),
                        ),
                      ),
                    );
                  }
                  final msg = _messages[i];
                  final mine = msg.role == 'user';
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 11, color: SWColors.violet),
                                  const SizedBox(width: 4),
                                  Text('SafeWalk AI',
                                      style: SWText.inter(size: 8.5, weight: FontWeight.w700, color: SWColors.violet)),
                                ],
                              ),
                            ),
                          Text(msg.content,
                              style: SWText.inter(
                                size: 11,
                                height: 1.45,
                                color: mine ? Colors.white : SWColors.ink,
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: SWColors.border))),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: SWColors.lavenderCard, borderRadius: BorderRadius.circular(20)),
                      child: TextField(
                        controller: _controller,
                        enabled: !_loading,
                        onSubmitted: _send,
                        style: SWText.inter(size: 10.5, color: SWColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Ask about safety, lighting, best times…',
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
                    onTap: _loading ? null : () => _send(_controller.text),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _loading ? SWColors.lavenderMid : SWColors.violet,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
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
