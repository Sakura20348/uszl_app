import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
/// Reusable step indicator for the onboarding flow.
///
/// Each onboarding page passes its own [currentStep] (0-based):
///   whyUzsl   -> OnboardingProgress(currentStep: 0)
///   fromWhere -> OnboardingProgress(currentStep: 1)
///   page 3    -> OnboardingProgress(currentStep: 2)
/// The dot at [currentStep] is shown active; the rest inactive.

class FeelingsOnboardingProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const FeelingsOnboardingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final bool isActive = index == currentStep;
        return Expanded(
          flex: isActive ? 3 : 2,
          child: Padding(padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 4), child: _dot(isActive))
        );
      }),
    );
  }

  Widget _dot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250), height: isActive ? 15 : 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isActive ? 10 : 5), border: Border.all(width: 1, color: AppPalette.border(Colors.blue).withOpacity(0.5)),
        color: isActive ? AppPalette.bg(Color(0xFF4A7FD0)) : AppPalette.bg(Color(0xFFE1F5FE)).withOpacity(0.9),
      ),
    );
  }
}

class ExamFeelingsOnboardingProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ExamFeelingsOnboardingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final bool isActive = index == currentStep;
        return Expanded(flex: isActive ? 3 : 2, child: Padding(padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 4), child: _dot(isActive)));
      }),
    );
  }

  Widget _dot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250), height: isActive ? 15 : 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isActive ? 10 : 5), border: Border.all(width: 1, color: AppPalette.border(Colors.blue).withOpacity(0.5)),
        color: isActive ? AppPalette.bg(Color(0xFF4A7FD0)) : AppPalette.bg(Color(0xFFE1F5FE)).withOpacity(0.9),
      ),
    );
  }
}