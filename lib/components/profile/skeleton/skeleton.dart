import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class ProfileSkeleton {
  static Widget buildSkeleton(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(height: 100, width: double.infinity, radius: 24),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: _box(height: 120, width: double.infinity, radius: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: _box(height: 120, width: double.infinity, radius: 24)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 4),
        _box(height: 400, width: double.infinity, radius: 24)
      ],
    );
  }

  static Widget _box({required double height, required double width, double radius = 8}){
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2))]
      ),
    );
  }
}

class PersonalInformationSkeleton {
  static Widget buildSkeleton(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _box(height: 44, width: 44, radius: 15),
              const SizedBox(height: 20),
              _box(height: 180, width: double.infinity, radius: 24)
            ],
          ),
        ),
        const SizedBox(height: 4),
        _box(height: 500, width: double.infinity, radius: 24)
      ],
    );
  }

  static Widget _box({required double height, required double width, double radius = 8}){
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2))]
      ),
    );
  }
}

class AllAchievementsSkeleton {
  static Widget buildSkeleton(){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 44, width: 44, radius: 15),
          const SizedBox(height: 18),
          _box(height: 36, width: 200),
          const SizedBox(height: 6),
          _box(height: 18, width: 250),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(6, (index) => _box(height: 160, width: 160, radius: 24)),
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
        color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2))]
      ),
    );
  }
}

class StatisticsSheetSkeleton {
  static Widget buildSkeleton(){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 44, width: 44, radius: 15),
          const SizedBox(height: 18),
          _box(height: 36, width: 250),
          const SizedBox(height: 8),
          _box(height: 18, width: 180),
          const SizedBox(height: 20),
          _box(height: 48, width: double.infinity, radius: 16),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _box(height: 120, width: double.infinity, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 120, width: double.infinity, radius: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _box(height: 120, width: double.infinity, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 120, width: double.infinity, radius: 20)),
            ],
          ),
          const SizedBox(height: 20),
          _box(height: 100, width: double.infinity, radius: 20),
          const SizedBox(height: 20),
          _box(height: 150, width: double.infinity, radius: 20),
        ]
      ),
    );
  }

  static Widget _box({required double height, required double width, double radius = 8}){
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2))]
      ),
    );
  }
}

class NotificationProfileSkeleton {
  static Widget buildSkeleton(){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 44, width: 44, radius: 15),
          const SizedBox(height: 18),
          _box(height: 36, width: 200),
          const SizedBox(height: 6),
          _box(height: 18, width: 250),
          const SizedBox(height: 20),
          _box(height: 80, width: double.infinity, radius: 24),
          const SizedBox(height: 18),
          Column(
            spacing: 12,
            children: List.generate(5, (index) => _box(height: 80, width: double.infinity, radius: 24)),
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
        color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2))]
      ),
    );
  }
}

class AboutSheetSkeleton {
  static Widget buildSkeleton(){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 44, width: 44, radius: 15),
          const SizedBox(height: 18),
          _box(height: 26, width: 280, radius: 15),
          const SizedBox(height: 10),
          _box(height: 18, width: double.infinity),
          const SizedBox(height: 4),
          _box(height: 18, width: 280),

          const SizedBox(height: 28),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_box(height: 120, width: 100), const SizedBox(height: 12), _box(height: 24, width: 250, radius: 15)],
            ),
          ),

          const SizedBox(height: 30),
          _box(height: 56, width: double.infinity, radius: 18),
          const SizedBox(height: 14),
          _box(height: 56, width: double.infinity, radius: 18),
          const SizedBox(height: 14),
          _box(height: 56, width: double.infinity, radius: 18),
          const SizedBox(height: 14),
          _box(height: 56, width: double.infinity, radius: 18),

          const SizedBox(height: 18),
          Center(child: _box(height: 16, width: 120)),

          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _box(height: 56, width: double.infinity, radius: 18)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 56, width: double.infinity, radius: 18)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 56, width: double.infinity, radius: 18)),
            ],
          ),
          const SizedBox(height: 18),
          Center(child: _box(height: 12, width: 100)),
        ],
      ),
    );
  }

  static Widget _box({required double height, required double width, double radius = 8}){
    return Container(
      height: height, width: width,
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2))]
      ),
    );
  }
}