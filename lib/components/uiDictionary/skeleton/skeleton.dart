import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class DictionarySkeleton {
  static Widget buildSkeleton(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [_box(height: 44, width: 44, radius: 15), const SizedBox(width: 12), _box(height: 44, width: 44, radius: 15)]),
              const SizedBox(height: 16), _box(height: 56, width: double.infinity, radius: 16), const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _box(height: 28, width: 90, radius: 10), const SizedBox(width: 8),
                    _box(height: 28, width: 90, radius: 10), const SizedBox(width: 8),
                    _box(height: 28, width: 90, radius: 10), const SizedBox(width: 8),
                    _box(height: 28, width: 90, radius: 10), const SizedBox(width: 8),
                    _box(height: 28, width: 90, radius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 24), _box(height: 510, width: double.infinity, radius: 24)
      ],
    );
  }

  static Widget _item(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _box(height: 44, width: 44, radius: 44), const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_box(height: 14, width: 180), const SizedBox(height: 6), _box(height: 12, width: 220)])
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

class ResultLessonsSkeleton {
  static Widget buildSkeleton(){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _box(height: 44, width: 44, radius: 15),
              Row(children: [_box(height: 44, width: 44, radius: 15), const SizedBox(width: 12), _box(height: 44, width: 44, radius: 15)])
            ],
          ),

          const SizedBox(height: 18), _box(height: 200, width: double.infinity, radius: 24),

          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_box(height: 24, width: 110), _box(height: 24, width: 110), _box(height: 24, width: 110)]),

          const SizedBox(height: 16), _box(height: 32, width: 130, radius: 25),
          const SizedBox(height: 8), _box(height: 18, width: 110),

          const SizedBox(height: 16), _box(height: 80, width: double.infinity, radius: 24),
          const SizedBox(height: 12), _box(height: 80, width: double.infinity, radius: 24),
          const SizedBox(height: 12), _box(height: 80, width: double.infinity, radius: 24),

          const SizedBox(height: 16), _box(height: 60, width: double.infinity, radius: 20),

          const SizedBox(height: 16), _box(height: 20, width: 150, radius: 15),

          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _box(height: 150, width: 150, radius: 24), const SizedBox(width: 12),
                _box(height: 150, width: 150, radius: 24), const SizedBox(width: 12),
                _box(height: 150, width: 150, radius: 24)
              ],
            ),
          )
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

class AllPhrasesSkeleton {
  static Widget buildSkeleton() {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 44, width: 44, radius: 10),
          const SizedBox(height: 16),
          _box(height: 30, width: 200, radius: 20),
          const SizedBox(height: 16),
          ...List.generate(8, (i) => _item()),
        ],
      ),
    );
  }

  static Widget _item(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [_box(height: 65, width: double.infinity, radius: 20), const SizedBox(height: 16), _box(height: 65, width: double.infinity, radius: 20)],
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