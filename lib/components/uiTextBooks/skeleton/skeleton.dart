import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class TextBooksSkeleton {
  static Widget buildSkeleton(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _box(height: 44, width: 44, radius: 44),
                  _box(height: 44, width: 230, radius: 18),
                  _box(height: 44, width: 44, radius: 15)
                ],
              ),

              const SizedBox(height: 16), _box(height: 14, width: 120),
              const SizedBox(height: 12), _box(height: 24, width: 230, radius: 24),

              const SizedBox(height: 16), _box(height: 160, width: double.infinity, radius: 24)
            ]
          )
        ),
        const SizedBox(height: 24), _box(height: 400, width: double.infinity, radius: 24)
      ]
    );
  }

  static Widget _item(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _box(height: 44, width: 44, radius: 44), const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(height: 14, width: 180), const SizedBox(height: 6),
              _box(height: 12, width: 220)
            ],
          )
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
}

class AllLessonsSkeleton {
  static Widget buildSkeleton(){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 44, width: 44, radius: 15),

          const SizedBox(height: 18), _box(height: 26, width: 150, radius: 24),
          const SizedBox(height: 12), _box(height: 16, width: 250),

          const SizedBox(height: 16), _box(height: 200, width: double.infinity, radius: 24),
          const SizedBox(height: 16), _box(height: 200, width: double.infinity, radius: 24),
          const SizedBox(height: 16), _box(height: 200, width: double.infinity, radius: 24),
          const SizedBox(height: 16), _box(height: 200, width: double.infinity, radius: 24),
          const SizedBox(height: 16), _box(height: 200, width: double.infinity, radius: 24),
          const SizedBox(height: 16), _box(height: 200, width: double.infinity, radius: 24),
        ],
      ),
    );
  }

  static Widget _box({required double height, required double width, double radius = 8}){
    return Container(
      height: height, width: width,
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 2))]
      ),
    );
  }
}

class NotificationSkeleton {
  static Widget buildSkeleton(){
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _box(height: 6, width: 65), const SizedBox(height: 25), _box(height: 168, width: 142),

          const SizedBox(height: 18), _box(height: 24, width: 250),
          const SizedBox(height: 16), _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 250),
          const SizedBox(height: 12), _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 250),
          const SizedBox(height: 12), _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 280),
          const SizedBox(height: 12), _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 230),

          _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 280),
          const SizedBox(height: 12), _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 280),
          const SizedBox(height: 12), _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 280),
          const SizedBox(height: 12), _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 280),
          const SizedBox(height: 12), _box(height: 12, width: double.infinity),
          const SizedBox(height: 6), _box(height: 12, width: 280),
          const SizedBox(height: 12),

          const SizedBox(height: 30), _box(height: 50, width: double.infinity, radius: 24),
          const SizedBox(height: 12), _box(height: 50, width: double.infinity, radius: 24)
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
}

// =======================================================================
// ALPHABET LESSONS
// =======================================================================
class AlphabetLessonsSkeleton {
  static Widget buildSkeleton(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(height: 44, width: 44, radius: 15),

              const SizedBox(height: 16), _box(height: 24, width: 140, radius: 22),
              const SizedBox(height: 12), _box(height: 12, width: 180),

              const SizedBox(height: 16), _box(height: 60, width: double.infinity, radius: 24)
            ]
          )
        ),
        const SizedBox(height: 24), _box(height: 510, width: double.infinity, radius: 24)
      ],
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
}

class StartOneLessonsSkeleton {
  static Widget buildSkeleton(){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 44, width: 44, radius: 15),

          const SizedBox(height: 16), _box(height: 200, width: double.infinity, radius: 24),

          const SizedBox(height: 16), _box(height: 24, width: 140, radius: 22),
          const SizedBox(height: 12), _box(height: 12, width: 200),

          const SizedBox(height: 16), _box(height: 80, width: double.infinity, radius: 24),

          const SizedBox(height: 16), _box(height: 80, width: double.infinity, radius: 24),

          const SizedBox(height: 145), _box(height: 50, width: double.infinity, radius: 24),
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
}
