import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
/// Reusable step indicator for the onboarding flow.
///
/// Each onboarding page passes its own [currentStep] (0-based):
///   whyUzsl   -> OnboardingProgress(currentStep: 0)
///   fromWhere -> OnboardingProgress(currentStep: 1)
///   page 3    -> OnboardingProgress(currentStep: 2)
/// The dot at [currentStep] is shown active; the rest inactive.
class OnboardingProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final bool isActive = index == currentStep;
        return Padding(padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 4), child: _dot(isActive));
      }),
    );
  }

  Widget _dot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250), height: isActive ? 15 : 10, width: isActive ? 35 : 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isActive ? 10 : 5), border: Border.all(width: 1, color: AppPalette.border(Colors.blue).withValues(alpha: 0.5)),
        color: isActive ? AppPalette.bg(Color(0xFF4A7FD0)) : AppPalette.bg(Color(0xFFE1F5FE)).withValues(alpha: 0.9),
      ),
    );
  }
}
