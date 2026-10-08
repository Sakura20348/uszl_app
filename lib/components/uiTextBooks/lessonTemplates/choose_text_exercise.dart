import 'package:flutter/material.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/services/theme_service.dart';

import 'lesson_parts.dart';

/// Template 1 — sign video + "Bu qaysi …?" + answer pills in two columns.
class ChooseTextExercise extends StatefulWidget {
  final ApiExercise exercise;
  final AnswerResult? result;
  final String question;
  final ValueChanged<Map<String, dynamic>?> onAnswer;
  const ChooseTextExercise({super.key, required this.exercise, required this.result, required this.question, required this.onAnswer});

  @override
  State<ChooseTextExercise> createState() => _ChooseTextExerciseState();
}

class _ChooseTextExerciseState extends State<ChooseTextExercise> {
  int? _selected;

  void _pick(int id) {
    if (widget.result != null) return;
    setState(() => _selected = id);
    widget.onAnswer({'optionId': id});
  }

  bool? _verdict(ApiOption o) {
    final r = widget.result;
    if (r == null) return null;
    if (o.id == r.correctOptionId) return true;
    return o.id == _selected ? false : null;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.exercise.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonVideoBox(url: widget.exercise.signVideo),
        const SizedBox(height: 20),
        Text(widget.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
        const SizedBox(height: 16),
        for (int i = 0; i < options.length; i += 2) ...[
          Row(children: [
            Expanded(child: _option(options[i])),
            const SizedBox(width: 12),
            Expanded(child: i + 1 < options.length ? _option(options[i + 1]) : const SizedBox()),
          ]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _option(ApiOption o) {
    final bool selected = _selected == o.id;
    final bool? correct = _verdict(o);
    final Color accent = lessonAccent(selected: selected, correct: correct);
    final bool highlighted = selected || correct == true;
    return GestureDetector(
      onTap: () => _pick(o.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18),
          border: Border.all(color: highlighted ? accent : AppPalette.border(Colors.white), width: 1.5),
          boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.25), blurRadius: 10)],
        ),
        child: Row(children: [
          Expanded(child: Text(o.text ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black87)))),
          const SizedBox(width: 6),
          LessonRadio(color: highlighted ? accent : AppPalette.border(Colors.black26), filled: highlighted),
        ]),
      ),
    );
  }
}
