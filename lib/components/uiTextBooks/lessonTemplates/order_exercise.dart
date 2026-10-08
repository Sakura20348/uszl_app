import 'package:flutter/material.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/services/theme_service.dart';

import 'lesson_parts.dart';

/// Template 3 — sign video + build the answer by tapping word chips (tap again to take one back).
class OrderExercise extends StatefulWidget {
  final ApiExercise exercise;
  final AnswerResult? result;
  final String question;
  final ValueChanged<Map<String, dynamic>?> onAnswer;
  const OrderExercise({super.key, required this.exercise, required this.result, required this.question, required this.onAnswer});

  @override
  State<OrderExercise> createState() => _OrderExerciseState();
}

class _OrderExerciseState extends State<OrderExercise> {
  final List<int> _answer = [];
  // the word bank is shown shuffled (the server keeps the right order)
  late final List<ApiOption> _bank = [...widget.exercise.options]..shuffle();

  void _report() => widget.onAnswer(_answer.isEmpty ? null : {'optionIds': List<int>.from(_answer)});

  void _place(int id) {
    if (widget.result != null || _answer.contains(id)) return;
    setState(() => _answer.add(id));
    _report();
  }

  void _remove(int id) {
    if (widget.result != null) return;
    setState(() => _answer.remove(id));
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final o in widget.exercise.options) o.id: o};
    final result = widget.result;
    final Color answerBorder = result == null ? AppPalette.border(lessonGreen) : (result.isCorrect ? AppPalette.border(lessonGreen) : AppPalette.border(Colors.redAccent));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonVideoBox(url: widget.exercise.signVideo),
        const SizedBox(height: 16),
        Text(widget.question, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppPalette.fg(const Color(0xFF0F172A)))),
        const SizedBox(height: 14),
        // --- the answer being built ---
        Container(
          width: double.infinity, constraints: const BoxConstraints(minHeight: 70), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
          child: Wrap(spacing: 10, runSpacing: 10, children: [for (final id in _answer) _chip(byId[id]?.text ?? '', onTap: () => _remove(id), border: answerBorder)]),
        ),
        const SizedBox(height: 14),
        // --- word bank (used words leave an empty slot) ---
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [for (final o in _bank) _answer.contains(o.id) ? _emptySlot(o.text ?? '') : _chip(o.text ?? '', onTap: () => _place(o.id), border: Colors.transparent)],
        ),
      ],
    );
  }

  Widget _chip(String text, {required VoidCallback onTap, required Color border}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 2),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.fg(const Color(0xFF334155)))),
    ),
  );

  Widget _emptySlot(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border(Colors.grey).withValues(alpha: 0.4), width: 1.5)),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.transparent)),
  );
}
