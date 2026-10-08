import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/profile/nameProfile/nameProfileSheet.dart';
import 'package:signlang/components/profile/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../customSwitch/customSwitch.dart';

import 'package:signlang/services/theme_service.dart';
class NotificationProfile extends StatefulWidget{
  const NotificationProfile({super.key});

  @override
  State<NotificationProfile> createState() => _NotificationProfileState();
}

class _NotificationProfileState extends State<NotificationProfile> {
  bool _isLoading = true;
  // defaults, used until the person changes a switch; saved as 'notif_<id>'
  static const Map<String, bool> _defaults = {
    '0': true, '1': false, '2': false, '3': false, '4': false, '5': false,
  };
  final Map<String, bool> _values = Map.of(_defaults);


  late final notificationItems = NotificationProfileData(context: context).notificationProfileItems;

// =======================================================================
  @override
  void initState(){ super.initState(); _initializeData(); }

// =======================================================================
  Future<void> _initializeData() async {
    final results = await Future.wait([SharedPreferences.getInstance(), AppLoading.ready()]);
    final prefs = results[0] as SharedPreferences;
    if (!mounted) return;
    setState(() {
      for (final id in _defaults.keys) { _values[id] = prefs.getBool('notif_$id') ?? _defaults[id]!; }
      _isLoading = false;
    });
  }

  Future<void> _handleToggle(String id, bool value) async {
    setState(() => _values[id] = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$id', value);
  }

  // "General" ('0') stays first; switched-on items move up under it, switched-off ones go back to their original place
  List<Map<String, dynamic>> _orderedItems() {
    final rest = notificationItems.where((e) => e['id'] != '0');
    return [
      ...notificationItems.where((e) => e['id'] == '0'),
      ...rest.where((e) => _values[e['id']] ?? false),
      ...rest.where((e) => !(_values[e['id']] ?? false)),
    ];
  }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: NotificationProfileSkeleton.buildSkeleton()))
                else
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.arrow_back_outlined),
                            )
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.translate('notifications'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                              Text(loc.translate('notifications_sub_title'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18))
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: _orderedItems().map((item) {
                            final id = item['id'];
                            return _SlideOnReorder(
                              key: ValueKey(id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(16), margin: EdgeInsets.only(bottom: (item['id'] == '0') ? 30 : 12),
                                  decoration: BoxDecoration(
                                    color: AppPalette.bg(Color(0xFFBBDEFB)).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppPalette.border(Colors.white), width: 1), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF90CAF9)).withOpacity(0.9), blurRadius: 15)]
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(12)),
                                        child: Image.asset(item['image'], width: 26, height: 26, errorBuilder: (_, __, ___) => Icon(Icons.account_circle, size: 25, color: AppPalette.fg(Colors.grey)))
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(item['titleKey'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
                                      CustomSwitch(value: _values[id] ?? false, onChanged: (val) => _handleToggle(id, val))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40)
                      ],
                    ),
                  )
              ],
            )
          )
        ),
      ),
    );
  }
}

/// Slides its child from where it was to where it is now whenever the parent Column reorders it.
class _SlideOnReorder extends StatefulWidget {
  final Widget child;
  const _SlideOnReorder({super.key, required this.child});

  @override
  State<_SlideOnReorder> createState() => _SlideOnReorderState();
}

class _SlideOnReorderState extends State<_SlideOnReorder> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  Offset _from = Offset.zero;
  Offset? _lastPos;

  Offset get _visualOffset => Offset.lerp(_from, Offset.zero, _curve.value)!;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  // after each layout, compare our spot in the Column with the previous one and animate the difference
  void _checkMoved(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final column = context.findAncestorRenderObjectOfType<RenderFlex>();
    if (box == null || column == null || !box.attached) return;
    final pos = box.localToGlobal(Offset.zero, ancestor: column);
    if (_lastPos != null && pos != _lastPos) {
      _from = _visualOffset + (_lastPos! - pos);
      _controller.forward(from: 0);
    }
    _lastPos = pos;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_checkMoved);
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Transform.translate(offset: _visualOffset, child: child),
      child: widget.child,
    );
  }
}
