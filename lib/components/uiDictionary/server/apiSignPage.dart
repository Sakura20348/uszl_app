import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/nameStore.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/lesson_parts.dart';
import 'package:signlang/components/web/download/download.dart';
import 'package:signlang/components/web/loading/bookLoading.dart';
import 'package:signlang/components/web/saved/saved.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/main.dart';
import 'package:signlang/services/theme_service.dart';

/// One sign from the server dictionary (made in the dashboard), with the same look as the app's own
/// sign pages: video, word, meaning / hand shape / movement, example sentence, related signs.
class ApiSignPage extends StatefulWidget {
  final int signId;
  const ApiSignPage({super.key, required this.signId});

  @override
  State<ApiSignPage> createState() => _ApiSignPageState();
}

class _ApiSignPageState extends State<ApiSignPage> {
  ApiSignDetail? _sign;
  bool _failed = false;
  bool _saved = false;

  // the texts come in the app language, which is read from the context
  bool _started = false;
  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) { _started = true; _load(); }
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final sign = await UzslApi.sign(widget.signId, lang: _lang);
      final saved = await SavedStore.instance.isSaved(sign.word);
      if (!mounted) return;
      setState(() { _sign = sign; _saved = saved; });
      // shows up in the dictionary's "Last seen" and can be reopened from there
      LastSeenStore.instance.add(sign.word, sign.thumbnail ?? '', source: 'api', id: '${sign.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _failed = true);
      showApiError(context, e, onRetry: _load);
    }
  }

  /// ✕: back to the dictionary home, sliding left like the app's own sign pages
  void _closeToDictionary() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainWrapper(initialTab: 1),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: animation.drive(Tween(begin: const Offset(-1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  Future<void> _toggleSave() async {
    final sign = _sign;
    if (sign == null) return;
    await SavedStore.instance.toggle({'word': sign.word, 'type': sign.kind == 'phrase' ? 'phrase' : 'word', 'source': 'dictionary', 'image': sign.thumbnail ?? ''});
    if (mounted) setState(() => _saved = !_saved);
  }

  void _showInfo(ApiSignDetail sign) {
    HapticFeedback.mediumImpact();
    final loc = AppLocalizations.of(context)!;
    final String text = [sign.meaning, if (sign.translationRu != null) 'RU · ${sign.translationRu}', if (sign.translationEn != null) 'EN · ${sign.translationEn}']
        .whereType<String>().where((t) => t.trim().isNotEmpty).join('\n');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppPalette.border(Colors.white), width: 1)),
        elevation: 1, backgroundColor: AppPalette.bg(Colors.white).withValues(alpha: 0.7), shadowColor: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.9),
        title: Text(sign.wordFor(_lang), style: TextStyle(fontWeight: FontWeight.w700, color: AppPalette.fg(const Color(0xFF0F172A)))),
        content: Text(text.isEmpty ? loc.translate('no_description') : text, style: TextStyle(color: AppPalette.fg(Colors.grey[800]!), fontSize: 14)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.translate('ok'), style: TextStyle(color: AppPalette.fg(Colors.black), fontWeight: FontWeight.w600, fontSize: 15)))],
      ),
    );
  }

  // the example sentence's own video, if the dashboard has one
  void _playExample(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16), backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(height: MediaQuery.of(context).size.height * 0.4, child: LessonVideoBox(url: url, showActions: false)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sign = _sign;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: sign == null
              ? Center(child: _failed
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(loc.translate('dict_load_failed'), style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: Text(loc.translate('try_again'))),
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('back'))),
                    ])
                  : BookLoader(label: loc.translate('loading')))
              : _page(loc, sign),
        ),
      ),
    );
  }

  Widget _page(AppLocalizations loc, ApiSignDetail sign) {
    final cards = [
      if (sign.meaning?.trim().isNotEmpty ?? false) (Icons.menu_book_rounded, loc.translate('meaning'), sign.meaning!),
      if (sign.handShape?.trim().isNotEmpty ?? false) (Icons.front_hand_rounded, loc.translate('hand_shape'), sign.handShape!),
      if (sign.movement?.trim().isNotEmpty ?? false) (Icons.swipe_rounded, loc.translate('sign_movement'), sign.movement!),
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(0, 20, 0, 24 + MediaQuery.of(context).viewPadding.bottom),
      children: [
        // ===== 1) back, download and save =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _square(Icon(Icons.close, color: AppPalette.fg(const Color(0xFF334155))), _closeToDictionary),
              Row(children: [
                _square(const Icon(Icons.download), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Download()))),
                const SizedBox(width: 12),
                _square(Icon(_saved ? Icons.bookmark : Icons.bookmark_border), _toggleSave),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // ===== 2) video (Qaytadan · speed · Burchak under it) with the info button =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              LessonVideoBox(key: ValueKey(sign.id), url: sign.videos.firstOrNull),
              Positioned(
                top: 18, right: 20,
                child: GestureDetector(
                  onTap: () => _showInfo(sign),
                  child: Container(
                    width: 46, height: 46, padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE3F2FD)).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(15), border: Border.all(width: 1, color: AppPalette.border(Colors.black).withValues(alpha: 0.2))),
                    child: Image.asset('web/icons/info_yellow.png', color: AppPalette.fg(Colors.grey)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ===== 3) word =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sign.wordFor(_lang), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
            if (sign.transcriptionFor(_lang) != null)
              Text('[${sign.transcriptionFor(_lang)}]', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: AppPalette.fg(Colors.grey[700]!))),
          ]),
        ),
        const SizedBox(height: 16),
        // ===== 4) meaning · hand shape · movement =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: 16), child: _infoCard(card.$1, card.$2, card.$3))]),
        ),
        // ===== 5) example sentence =====
        if (sign.exampleSentence?.trim().isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFBBDEFB)).withValues(alpha: 0.9), border: Border.all(width: 1.5, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Container(
                  width: 64, height: 64, clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE3F2FD)).withValues(alpha: 0.9), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                  child: sign.thumbnail != null
                      ? Image.network(sign.thumbnail!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.person, size: 30, color: AppPalette.fg(Colors.blue)))
                      : Icon(Icons.person, size: 30, color: AppPalette.fg(Colors.blue)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(loc.translate('example_sentence'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                  Text('“${sign.exampleSentence}”', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: AppPalette.fg(Colors.grey[700]!))),
                ])),
                if (sign.exampleVideo != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _playExample(sign.exampleVideo!),
                    child: Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE3F2FD)).withValues(alpha: 0.9), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                      child: Center(child: Container(height: 20, width: 20, decoration: BoxDecoration(color: AppPalette.bg(lessonBlue), shape: BoxShape.circle), child: Icon(Icons.play_arrow, color: AppPalette.fg(Colors.white), size: 14))),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        // ===== 6) related signs =====
        if (sign.related.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(loc.translate('related_gestures'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24))),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: sign.related.length, itemBuilder: (_, i) => _relatedCard(sign.related[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _square(Widget icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 46, height: 46, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: icon),
  );

  Widget _infoCard(IconData icon, String title, String body) => Container(
    width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
    decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFBBDEFB)).withValues(alpha: 0.9), border: Border.all(width: 1.5, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      Container(
        width: 50, height: 50,
        decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE3F2FD)).withValues(alpha: 0.9), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
        child: Icon(icon, color: AppPalette.fg(lessonBlue)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        Text(body, style: TextStyle(fontSize: 14, color: AppPalette.fg(Colors.grey[700]!))),
      ])),
    ]),
  );

  Widget _relatedCard(ApiSign item) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApiSignPage(signId: item.id))),
    child: Container(
      width: 150, margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFBBDEFB)).withValues(alpha: 0.7), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        // picture
        Positioned.fill(
          top: 15,
          child: item.thumbnail != null
              ? Image.network(item.thumbnail!, fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.person, size: 60, color: AppPalette.fg(Colors.blue)))
              : Icon(Icons.person, size: 60, color: AppPalette.fg(Colors.blue)),
        ),
        // play badge
        Positioned(
          top: 10, right: 10,
          child: Container(
            height: 35, width: 35, decoration: BoxDecoration(color: AppPalette.bg(lessonBlue).withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Center(child: Container(height: 20, width: 20, decoration: BoxDecoration(color: AppPalette.bg(lessonBlue), shape: BoxShape.circle), child: Icon(Icons.play_arrow, color: AppPalette.fg(Colors.white), size: 18))),
          ),
        ),
        // word
        Positioned(
          left: 10, right: 10, bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.white).withValues(alpha: 0.9), blurRadius: 15)]),
            child: Center(child: Text(item.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(const Color(0xFF0F172A))))),
          ),
        ),
      ]),
    ),
  );
}
