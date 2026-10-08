import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A category icon like the dashboard's: a Solar line icon ("solar:pills-linear"),
/// bundled in assets/icons/solar so it shows offline too, tinted with [color].
class CategoryIcon extends StatelessWidget {
  final String? name;
  final double size;
  final Color color;
  const CategoryIcon(this.name, {super.key, this.size = 20, required this.color});

  /// "All" chip, as in the dashboard
  static const String all = 'solar:widget-4-linear';
  /// The dashboard's icon for categories without one
  static const String fallback = 'solar:hand-shake-linear';

  /// Icons the app has; the same list the dashboard offers for new categories
  static const Set<String> bundled = {
    'widget-4', 'hand-shake', 'users-group-rounded', 'donut-bitten', 'hashtag', 'pills', 'text-square', 'bus', 'buildings-2',
    'basketball', 'emoji-funny-circle', 'home-smile', 'palette', 'leaf', 'cat', 't-shirt', 'sun-2', 'case', 'heart-pulse',
  };

  /// The dashboard's icons of the categories the app had before, for when it's offline
  static const Map<String, String> bySlug = {
    'family': 'solar:users-group-rounded-linear', 'food': 'solar:donut-bitten-linear', 'numbers': 'solar:hashtag-linear',
    'medicine': 'solar:pills-linear', 'alphabet': 'solar:text-square-linear', 'transportation': 'solar:bus-linear',
    'public-services': 'solar:buildings-2-linear', 'sports': 'solar:basketball-linear', 'feelings': 'solar:emoji-funny-circle-linear',
    'daily-life': 'solar:home-smile-linear',
  };

  static String _asset(String? name) {
    final n = (name ?? '').replaceFirst('solar:', '').replaceFirst(RegExp(r'-linear$'), '');
    return 'assets/icons/solar/${bundled.contains(n) ? n : 'hand-shake'}-linear.svg';
  }

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    _asset(name), width: size, height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}
