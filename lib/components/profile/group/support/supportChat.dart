import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';

/// Profile → Help: the learner writes to the team; admins answer on the dashboard (Messages)
/// and the reply also comes as a notification.
class SupportChat extends StatefulWidget {
  const SupportChat({super.key});

  @override
  State<SupportChat> createState() => _SupportChatState();
}

class _SupportChatState extends State<SupportChat> {
  static const Color _blue = Color(0xFF477BC9);

  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<SupportMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // A reply can come while the chat is open
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final messages = await UzslApi.supportMessages();
      if (!mounted) return;
      final grew = messages.length != _messages.length;
      setState(() { _messages = messages; _loading = false; });
      if (grew) _toBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!quiet) showApiError(context, e, onRetry: _load);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await UzslApi.writeToSupport(text);
      if (!mounted) return;
      _input.clear();
      setState(() => _messages = [..._messages, message]);
      _toBottom();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e, onRetry: _send);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  });

  String _time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} · ${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // ===== top bar =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(16)),
                        child: Icon(Icons.arrow_back, color: AppPalette.fg(const Color(0xFF334155)), size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.translate('support_title'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.fg(const Color(0xFF0F172A)))),
                          Text(loc.translate('support_subtitle'), style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[600]!))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ===== messages =====
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? _empty(loc)
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) => _bubble(_messages[i], loc),
                          ),
              ),
              // ===== input =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1, maxLines: 5, maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: loc.translate('support_placeholder'), counterText: '',
                          filled: true, fillColor: AppPalette.bg(Colors.white),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _blue, shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : _send,
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: _sending
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(AppLocalizations loc) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), shape: BoxShape.circle),
            child: Image.asset('web/icons/message_circle_question_mark.png', width: 36, height: 36, color: AppPalette.auto(_blue)),
          ),
          const SizedBox(height: 16),
          Text(loc.translate('support_empty_title'), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.fg(const Color(0xFF0F172A)))),
          const SizedBox(height: 6),
          Text(loc.translate('support_empty_text'), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppPalette.fg(Colors.grey[600]!))),
        ],
      ),
    ),
  );

  Widget _bubble(SupportMessage m, AppLocalizations loc) {
    // The learner's own messages on the right, the team's on the left
    final bool mine = !m.fromAdmin;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppPalette.auto(_blue) : AppPalette.bg(Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4), bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine) Text(loc.translate('support_team'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppPalette.auto(_blue))),
            Text(m.text, style: TextStyle(fontSize: 15, color: mine ? Colors.white : AppPalette.fg(const Color(0xFF0F172A)))),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(_time(m.createdAt), style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : AppPalette.fg(Colors.grey[500]!))),
            ),
          ],
        ),
      ),
    );
  }
}
