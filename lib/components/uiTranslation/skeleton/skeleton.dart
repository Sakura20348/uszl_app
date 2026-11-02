import 'package:flutter/material.dart';

import '../../../services/theme_service.dart';

class TranslationSkeleton {
  static Widget buildSkeleton(){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          _box(height: 18, width: 220, radius: 20),
          const SizedBox(height: 18),
          _box(height: 14, width: 300, radius: 12),
          const SizedBox(height: 6),
          _box(height: 14, width: 230, radius: 12),
          const SizedBox(height: 18),
          ...List.generate(5, (index) => _item())
        ],
      ),
    );
  }
  static Widget _box({required double height, required double width, double radius = 8}){
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 2))]
      ),
    );
  }

  static Widget _item(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box(height: 100, width: double.infinity, radius: 18)
          ],
        )
    );
  }
}