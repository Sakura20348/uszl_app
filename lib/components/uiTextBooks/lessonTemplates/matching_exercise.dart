import 'package:flutter/material.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/services/theme_service.dart';

import 'lesson_parts.dart';

/// Template 4 — match each sign (video or picture) on the left with its word on the right.
/// Tap a sign, then its word; matched pairs share a colour. Tap again to undo.
class MatchingExercise extends StatefulWidget {
  final ApiExercise exercise;
  final AnswerResult? result;
  final String question;
  final ValueChanged<Map<String, dynamic>?> onAnswer;
  const MatchingExercise({super.key, required this.exercise, required this.result, required this.question, required this.onAnswer});

  @override
  State<MatchingExercise> createState() => _MatchingExerciseState();
}

class _MatchingExerciseState extends State<MatchingExercise> {
  late final List<ApiOption> _words = [...widget.exercise.options]..shuffle();
  final Map<int, int> _pairs = {}; // sign option id → word option id
  int? _selectedSign;

  static const List<Color> _pairColors = [Color(0xFF42A5F5), Color(0xFFAB47BC), Color(0xFFFFA726), Color(0xFF26A69A), Color(0xFFEC407A), Color(0xFF8D6E63)];

  Color? _colorOf(int signId) {
    final i = _pairs.keys.toList().indexOf(signId);
    return i < 0 ? null : _pairColors[i % _pairColors.length];
  }

  void _report() {
    final done = _pairs.length == widget.exercise.options.length;
    widget.onAnswer(done ? {'pairs': [for (final e in _pairs.entries) [e.key, e.value]]} : null);
  }

  void _tapSign(int id) {
    if (widget.result != null) return;
    setState(() { _pairs.remove(id); _selectedSign = id; });
    _report();
  }

  void _tapWord(int id) {
    if (widget.result != null) return;
    setState(() {
      final owner = _pairs.entries.where((e) => e.value == id).map((e) => e.key).firstOrNull;
      if (owner != null) {
        _pairs.remove(owner);
      } else if (_selectedSign != null) {
        _pairs[_selectedSign!] = id;
        _selectedSign = null;
      }
    });
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final bool checked = widget.result != null;
    Color borderFor({required bool selected, Color? pair, bool? correct}) =>
        correct != null ? lessonAccent(selected: false, correct: correct) : (pair ?? (selected ? AppPalette.auto(lessonBlue) : AppPalette.border(Colors.white)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- signs ---
            Expanded(
              child: Column(children: [
                for (final o in widget.exercise.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _tapSign(o.id),
                      child: Container(
                        width: double.infinity, height: 118, padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(18),
                          border: Border.all(width: 2.5, color: borderFor(selected: _selectedSign == o.id, pair: _colorOf(o.id), correct: checked && _pairs.containsKey(o.id) ? _pairs[o.id] == o.id : null)),
                          boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.2), blurRadius: 10)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: o.signVideo != null
                              ? IgnorePointer(child: LessonVideoBox(url: o.signVideo, showActions: false))
                              : (o.image != null ? Image.network(o.image!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image)) : const Icon(Icons.help_outline)),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 12),
            // --- words ---
            Expanded(
              child: Column(children: [
                for (final w in _words)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _tapWord(w.id),
                      child: Container(
                        height: 118, alignment: Alignment.center, padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18),
                          border: Border.all(width: 2.5, color: borderFor(selected: false, pair: _pairs.entries.where((e) => e.value == w.id).map((e) => _colorOf(e.key)).firstOrNull)),
                          boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.2), blurRadius: 10)],
                        ),
                        child: Text(w.text ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black87))),
                      ),
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}
