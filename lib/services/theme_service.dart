import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSeason { spring, summer, autumn, winter }

/// App-wide light/dark mode and season colors, persisted in SharedPreferences.
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _key = 'themeMode';
  static const String _seasonKey = 'seasonChoice';

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  /// What the user picked; null = follows the date.
  final ValueNotifier<AppSeason?> seasonChoice = ValueNotifier(null);
  /// The season whose colors are showing. Winter is the app's original blue.
  final ValueNotifier<AppSeason> season = ValueNotifier(AppSeason.winter);

  bool get isDark => mode.value == ThemeMode.dark;

  static AppSeason seasonOf(DateTime date) => switch (date.month) {
    3 || 4 || 5 => AppSeason.spring,
    6 || 7 || 8 => AppSeason.summer,
    9 || 10 || 11 => AppSeason.autumn,
    _ => AppSeason.winter,
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = prefs.getString(_key) == 'dark' ? ThemeMode.dark : ThemeMode.light;
    final saved = prefs.getString(_seasonKey);
    seasonChoice.value = AppSeason.values.where((s) => s.name == saved).firstOrNull;
    refreshSeason();
  }

  /// Also called when the app comes back: the date may have moved into a new season.
  void refreshSeason() {
    final next = seasonChoice.value ?? seasonOf(DateTime.now());
    if (next == season.value) return;
    AppPalette.clearSeason();
    season.value = next;
  }

  Future<void> setSeason(AppSeason? value) async {
    seasonChoice.value = value;
    refreshSeason();
    final prefs = await SharedPreferences.getInstance();
    if (value == null) { await prefs.remove(_seasonKey); } else { await prefs.setString(_seasonKey, value.name); }
  }

  Future<void> toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value == ThemeMode.dark ? 'dark' : 'light');
  }
}

class AppThemes {
  static const PageTransitionsTheme _transitions = PageTransitionsTheme(builders: {
    TargetPlatform.android: FastPageTransitionsBuilder(),
    TargetPlatform.iOS: FastPageTransitionsBuilder(),
    TargetPlatform.linux: FastPageTransitionsBuilder(),
    TargetPlatform.macOS: FastPageTransitionsBuilder(),
    TargetPlatform.windows: FastPageTransitionsBuilder(),
    TargetPlatform.fuchsia: FastPageTransitionsBuilder(),
  });

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    pageTransitionsTheme: _transitions,
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF10151C),
    pageTransitionsTheme: _transitions,
  );
}

/// Shared palette for the glassy blue UI, in light and dark variants.
class AppColors {
  final bool isDark;
  const AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) => AppColors._(Theme.of(context).brightness == Brightness.dark);

  List<Color> get bgGradient => isDark ? [AppPalette.seasonAll(const Color(0xFF0F2336)), const Color(0xFF10151C)] : [AppPalette.season(const Color(0xFFBBDEFB)), Colors.white];
  Color get surface => isDark ? const Color(0xFF161C24) : Colors.white;
  Color get card => isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.4);
  Color get cardBorder => isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white;
  Color get glow => AppPalette.season(const Color(0xFF42A5F5)).withValues(alpha: isDark ? 0.25 : 0.9);
  Color get chip => isDark ? Colors.white.withValues(alpha: 0.08) : AppPalette.season(const Color(0xFFE3F2FD)).withValues(alpha: 0.6);
  Color get text => isDark ? const Color(0xFFE6EDF5) : const Color(0xFF0F172A);
  Color get subText => isDark ? const Color(0xFF9AA8B8) : Colors.grey[600]!;
  Color get accent => AppPalette.season(isDark ? const Color(0xFF90CAF9) : const Color(0xFF0D47A1));
  Color get track => isDark ? Colors.white.withValues(alpha: 0.12) : AppPalette.season(const Color(0xFFD6E4F0));
}

/// Short fade + slide used for every MaterialPageRoute (default Android one is 450ms).
class FastPageTransitionsBuilder extends PageTransitionsBuilder {
  const FastPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(opacity: curved, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved), child: child));
  }
}

/// Context-free color mapping used by screens with hardcoded light-theme colors.
/// Blues first take the season's color. Then, in light mode, every function returns
/// the color as it is; in dark mode light backgrounds are darkened and dark
/// foregrounds lightened, keeping the hue.
class AppPalette {
  AppPalette._();

  static bool get _dark => ThemeService.instance.isDark;

  // Only pale tints count as backgrounds; saturated accents (e.g. 0xFF42A5F5) stay as they are.
  static const double _paleLimit = 0.72;

  static final Map<int, Color> _bg = {}, _fg = {}, _border = {}, _shadow = {}, _season = {};

  static Color _cached(Map<int, Color> cache, Color c, Color Function(Color) map) => cache.putIfAbsent(c.toARGB32(), () => map(c));

  static void clearSeason() => _season.clear();

  /// The app's blues in the current season's color. Other hues (status greens and reds) and
  /// very dark blues (body text) stay as they are.
  static Color season(Color c) => ThemeService.instance.season.value == AppSeason.winter ? c : _cached(_season, c, (c) => _toSeason(c, keepDark: true));

  /// Same, for very dark blues too (dark mode backgrounds).
  static Color seasonAll(Color c) => ThemeService.instance.season.value == AppSeason.winter ? c : _toSeason(c, keepDark: false);

  static Color _toSeason(Color c, {required bool keepDark}) {
    final h = HSLColor.fromColor(c);
    if (h.hue < 180 || h.hue > 245 || h.saturation < 0.2 || (keepDark && h.lightness < 0.3)) return c;
    final (double hue, double saturation, double lightness) = switch (ThemeService.instance.season.value) {
      AppSeason.spring => (142, 1.0, 1.0),
      AppSeason.summer => (42, 1.4, h.lightness < 0.7 ? 0.92 : 1.0), // darker accents: white text stays readable
      AppSeason.autumn => (24, 1.2, 1.0),
      AppSeason.winter => (h.hue, 1.0, 1.0),
    };
    return h.withHue(hue).withSaturation((h.saturation * saturation).clamp(0.0, 1.0)).withLightness(h.lightness * lightness).toColor();
  }

  /// Surfaces, fills, gradients.
  static Color bg(Color c) { final s = season(c); return _dark ? _cached(_bg, s, _toDarkBg) : s; }

  /// Text, icons, image tints.
  static Color fg(Color c) { final s = season(c); return _dark ? _cached(_fg, s, _toLightFg) : s; }

  /// Border and divider lines.
  static Color border(Color c) { final s = season(c); return _dark ? _cached(_border, s, _toDarkBorder) : s; }

  /// Shadows and glows.
  static Color shadow(Color c) { final s = season(c); return _dark ? _cached(_shadow, s, _toDarkShadow) : s; }

  /// Role unknown (e.g. a color stored in a variable): light colors act as backgrounds, dark ones as text.
  static Color auto(Color color) {
    final c = season(color);
    if (!_dark) return c;
    final double l = HSLColor.fromColor(c).lightness;
    if (l > _paleLimit) return bg(c);
    if (l < 0.4) return fg(c);
    return c;
  }

  static Color _toDarkBg(Color c) {
    final h = HSLColor.fromColor(c);
    if (h.lightness <= _paleLimit) return c;
    if (h.saturation < 0.08 && h.lightness > 0.95) return const Color(0xFF161C24).withAlpha((c.a * 255).round());
    return h.withSaturation(h.saturation * 0.5).withLightness(0.08 + (1 - h.lightness)).toColor();
  }

  static Color _toLightFg(Color c) {
    final h = HSLColor.fromColor(c);
    if (h.lightness >= 0.5) return c;
    return h.withSaturation(h.saturation * 0.7).withLightness(1 - h.lightness * 0.75).toColor();
  }

  static Color _toDarkBorder(Color c) {
    final h = HSLColor.fromColor(c);
    if (h.lightness <= _paleLimit) return c;
    final bool neutral = h.saturation < 0.08;
    return (neutral ? h.withHue(213).withSaturation(0.15) : h.withSaturation(h.saturation * 0.4)).withLightness(0.24).toColor();
  }

  static Color _toDarkShadow(Color c) {
    final h = HSLColor.fromColor(c);
    if (h.lightness > 0.8) return Colors.black.withAlpha((c.a * 255).round());
    return Color.lerp(c, Colors.black.withAlpha((c.a * 255).round()), 0.6)!;
  }
}
