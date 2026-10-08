// nav.dart
import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color selectedColor = isDark ? const Color(0xFF90CAF9) : Colors.blue[700]!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24).withOpacity(0.92) : Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(24),
        border: Border.all(width: 1, color: isDark ? Colors.white12 : Color(0xFFE3F2FD)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Color(0xFFBBDEFB).withOpacity(0.9), blurRadius: 15, spreadRadius: 1)]
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              final item = items[index];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 10), padding: const EdgeInsets.symmetric(vertical: 8), margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFBBDEFB).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: selected ? Color(0xFF90CAF9).withOpacity(isDark ? 0.25 : 0.9) : Colors.transparent, blurRadius: 15)]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 26, color: selected ? selectedColor : Colors.grey),
                        const SizedBox(height: 4),
                        Text(item.label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? selectedColor : Colors.grey))
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}