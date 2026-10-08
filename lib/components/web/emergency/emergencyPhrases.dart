import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:signlang/components/uiTextBooks/lessonCarouselWidgets.dart';
import 'package:signlang/components/web/saved/saved.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';

/// Emergency phrases: one-tap calls to emergency services + the key signs for urgent situations.
class EmergencyPhrases extends StatefulWidget {
  const EmergencyPhrases({super.key});

  @override
  State<EmergencyPhrases> createState() => _EmergencyPhrasesState();
}

class _EmergencyPhrasesState extends State<EmergencyPhrases> with SingleTickerProviderStateMixin {
  static const Color _red = Color(0xFFE53935);
  static const Color _redDark = Color(0xFFB71C1C);

  // Uzbekistan emergency numbers
  static const List<({String number, String labelKey, IconData icon, Color color})> _services = [
    (number: '103', labelKey: 'ambulance', icon: Icons.local_hospital_rounded, color: Color(0xFFE53935)),
    (number: '102', labelKey: 'police', icon: Icons.local_police_rounded, color: Color(0xFF1E88E5)),
    (number: '101', labelKey: 'fire_service', icon: Icons.local_fire_department_rounded, color: Color(0xFFFB8C00)),
    (number: '112', labelKey: 'emergency_112', icon: Icons.sos_rounded, color: Color(0xFF8E24AA)),
  ];

  // key = translation key of the word; its syllables are '<key>_phrases', how to show it is 'meaning_<key>'
  static const List<({String key, IconData icon})> _signs = [
    (key: 'help_1', icon: Icons.front_hand_rounded),
    (key: 'pain', icon: Icons.healing_rounded),
    (key: 'doctor', icon: Icons.medical_services_rounded),
    (key: 'ambulance', icon: Icons.airport_shuttle_rounded),
    (key: 'hospital', icon: Icons.local_hospital_rounded),
    (key: 'emergency_hospital', icon: Icons.emergency_rounded),
    (key: 'medicine', icon: Icons.medication_rounded),
    (key: 'painkiller', icon: Icons.medication_liquid_rounded),
    (key: 'police_station', icon: Icons.local_police_rounded),
    (key: 'fire_station', icon: Icons.fire_truck_rounded),
  ];

  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  final Set<String> _saved = {};

  @override
  void initState() { super.initState(); _loadSaved(); }

  @override
  void dispose() { _enter.dispose(); super.dispose(); }

  Future<void> _loadSaved() async {
    final items = await SavedStore.instance.load();
    if (mounted) setState(() { _saved..clear()..addAll(items.map((e) => e['word'] as String)); });
  }

  Future<void> _call(String number) async {
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  Future<void> _toggleSave(String word) async {
    await SavedStore.instance.toggle({'word': word, 'type': 'word', 'source': 'emergency'});
    await _loadSaved();
  }

  // staggered fade + slide-up, [start] in 0..1 of the entrance animation
  Widget _reveal(double start, Widget child) {
    final anim = CurvedAnimation(parent: _enter, curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic));
    return FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim), child: child));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = AppColors.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(loc)),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== 2) call services =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _reveal(0.1, _sectionTitle(loc.translate('emergency_call_title'), loc.translate('emergency_call_sub'), c)),
                  ),
                  const SizedBox(height: 12),
                  _reveal(0.15, _servicesGrid(loc, c)),
                  const SizedBox(height: 20),
                  // ===== 3) tip =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _reveal(0.25, _tipCard(loc, c)),
                  ),
                  const SizedBox(height: 24),
                  // ===== 4) signs =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _reveal(0.35, _sectionTitle(loc.translate('emergency_signs'), '', c)),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // a SliverGrid must sit directly in the slivers list (or in a SliverPadding), not in a SliverToBoxAdapter
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 32 + MediaQuery.of(context).viewPadding.bottom),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _reveal((0.4 + i * 0.04).clamp(0.0, 0.5), _signCard(_signs[i], loc, c)),
                  childCount: _signs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 1) header =====
  Widget _header(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppPalette.bg(const Color(0xFFEF5350)), AppPalette.bg(_redDark)]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(_red).withValues(alpha: 0.9), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 15, offset: const Offset(0, 4))]
              ),
              child: const Icon(Icons.arrow_back_outlined, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 15, offset: const Offset(0, 4))]
                ),
                child: Image.asset('web/icons/emergency.png', width: 32, height: 32, errorBuilder: (_, _, _) => const Icon(Icons.emergency, color: Colors.white, size: 32)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.translate('emergency_phrases'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(loc.translate('emergency_phrases_sub'), style: TextStyle(fontSize: 14, height: 1.35, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String sub, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.text)),
        if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 14, color: c.subText)),
      ],
    );
  }

  Widget _servicesGrid(AppLocalizations loc, AppColors c) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(10),
      clipBehavior: Clip.none, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.1,
      children: [
        for (final s in _services)
          Container(
            // shadow + border live here, outside Material, so nothing clips them
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPalette.border(s.color).withValues(alpha: 0.35)),
              boxShadow: [BoxShadow(color: AppPalette.shadow(s.color).withValues(alpha: 0.9), blurRadius: 15, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _call(s.number),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        height: 42, width: 42, decoration: BoxDecoration(color: AppPalette.bg(s.color).withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(s.icon, color: AppPalette.fg(s.color), size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.number, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppPalette.fg(s.color))),
                            Text(loc.translate(s.labelKey), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.subText)),
                          ],
                        ),
                      ),
                      Icon(Icons.call_rounded, size: 18, color: AppPalette.fg(s.color)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _tipCard(AppLocalizations loc, AppColors c) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bg(const Color(0xFFFFF3E0)).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border(const Color(0xFFFFB74D)).withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFFFFB74D)).withValues(alpha: 0.9), blurRadius: 15, offset: const Offset(0, 4))]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, color: AppPalette.fg(const Color(0xFFEF6C00))),
          const SizedBox(width: 12),
          Expanded(child: Text(loc.translate('emergency_tip'), style: TextStyle(fontSize: 14, height: 1.4, color: AppPalette.fg(const Color(0xFF5D4037))))),
        ],
      ),
    );
  }

  Widget _signCard(({String key, IconData icon}) sign, AppLocalizations loc, AppColors c) {
    final String word = loc.translate(sign.key);
    final bool saved = _saved.contains(word);
    const blue = Color(0xFF4A7FD0);

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.cardBorder),
        boxShadow: [BoxShadow(color: c.glow.withValues(alpha: 0.9), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias, // ripple stays inside the rounded corners
        child: InkWell(
          onTap: () => _openSign(sign),
          child: Padding(
            padding: const EdgeInsets.all(14), // ← inner padding (content inside the card)
            child: Stack(
              children: [
                // ===== big icon + word, centered =====
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 60, width: 60,
                        decoration: BoxDecoration(
                          color: AppPalette.bg(_red).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sign.icon, color: AppPalette.fg(_red).withValues(alpha: 0.9), size: 34),
                      ),
                      const SizedBox(height: 8),
                      Text(word, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
                    ],
                  ),
                ),
                // ===== play: top-right =====
                Positioned(top: 0, right: 0, child: Icon(Icons.play_circle_fill_rounded, size: 22, color: AppPalette.fg(blue))),
                // ===== saved: top-left =====
                if (saved) Positioned(top: 0, left: 0, child: Icon(Icons.bookmark, size: 20, color: AppPalette.fg(blue))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // sign details: video box, syllables and how to show it
  Future<void> _openSign(({String key, IconData icon}) sign) async {
    final loc = AppLocalizations.of(context)!;
    final String word = loc.translate(sign.key);
    final String syllables = loc.translate('${sign.key}_phrases');
    final String meaning = loc.translate('meaning_${sign.key}');
    // translate() returns the key itself when a text is missing
    final bool hasSyllables = syllables.isNotEmpty && syllables != '${sign.key}_phrases';
    final bool hasMeaning = meaning.isNotEmpty && meaning != 'meaning_${sign.key}';

    await showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final c = AppColors.of(sheetContext);
          final bool saved = _saved.contains(word);
          // keep the content above the phone's navigation bar (gesture bar or buttons)
          final double navBar = MediaQuery.of(sheetContext).viewPadding.bottom;
          return Container(
            decoration: BoxDecoration(color: c.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + navBar),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 18),
                  Container(
                    height: 190, width: double.infinity,
                    decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(20)),
                    child: const LessonVideoUnavailable(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Text(word, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: c.text))),
                      IconButton.filledTonal(
                        onPressed: () async { await _toggleSave(word); setSheet(() {}); },
                        icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: AppPalette.fg(const Color(0xFF4A7FD0))),
                      ),
                    ],
                  ),
                  if (hasSyllables) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE3F2FD)), borderRadius: BorderRadius.circular(12)),
                      child: Text('${loc.translate('syllables')}: $syllables', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.fg(const Color(0xFF1565C0)))),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(loc.translate('how_to_show'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
                  const SizedBox(height: 6),
                  Text(hasMeaning ? meaning : loc.translate('no_description'), style: TextStyle(fontSize: 15, height: 1.45, color: c.subText)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
