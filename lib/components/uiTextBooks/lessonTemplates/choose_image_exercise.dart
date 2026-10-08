import 'package:flutter/material.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/services/theme_service.dart';

import 'lesson_parts.dart';

/// Template 2 — "Qaysi biri …?" + four picture (or sign video) cards with a label and a radio.
class ChooseImageExercise extends StatefulWidget {
  final ApiExercise exercise;
  final AnswerResult? result;
  final String question;
  final ValueChanged<Map<String, dynamic>?> onAnswer;
  const ChooseImageExercise({super.key, required this.exercise, required this.result, required this.question, required this.onAnswer});

  @override
  State<ChooseImageExercise> createState() => _ChooseImageExerciseState();
}

class _ChooseImageExerciseState extends State<ChooseImageExercise> {
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
        Text(widget.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 28)),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0),
          itemCount: options.length,
          itemBuilder: (context, i) => _card(options[i]),
        ),
      ],
    );
  }

  Widget _card(ApiOption o) {
    final bool selected = _selected == o.id;
    final bool? correct = _verdict(o);
    final Color accent = lessonAccent(selected: selected, correct: correct);
    final bool highlighted = selected || correct == true;
    return GestureDetector(
      onTap: () => _pick(o.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: highlighted ? accent : Colors.transparent, width: 2),
          boxShadow: highlighted ? [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Stack(
          children: [
            // --- picture or sign video ---
            Positioned.fill(
              bottom: 34,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: o.image != null
                    ? Image.network(o.image!, fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.image_not_supported, size: 50, color: AppPalette.fg(Colors.grey)))
                    : (o.signVideo != null ? LessonVideoBox(url: o.signVideo, showActions: false) : Icon(Icons.sign_language, size: 50, color: AppPalette.fg(Colors.blue))),
              ),
            ),
            // --- label ---
            if (o.text?.isNotEmpty == true)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16), border: Border.all(width: selected ? 0.5 : 0.1)),
                  child: Text(o.text!, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: selected ? AppPalette.fg(const Color(0xFF1E293B)) : AppPalette.fg(Colors.grey))),
                ),
              ),
            // --- radio ---
            Positioned(top: 2, right: 2, child: LessonRadio(color: highlighted ? accent : AppPalette.auto(Colors.black12), filled: highlighted)),
          ],
        ),
      ),
    );
  }
}
