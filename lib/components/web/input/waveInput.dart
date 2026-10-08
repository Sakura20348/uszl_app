import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class WaveInput extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const WaveInput({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
  });

  @override
  State<WaveInput> createState() => _WaveInputState();
}

class _WaveInputState extends State<WaveInput> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  static final Color _accent = AppPalette.auto(Color(0xFF1A237E));
  static const double _width = 90;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool floated = _isFocused || _controller.text.isNotEmpty;

    return SizedBox(
      width: _width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ===== the input + bottom border =====
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  textCapitalization: TextCapitalization.none,
                  style: const TextStyle(fontSize: 20),
                  cursorColor: _accent,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.fromLTRB(5, 10, 10, 10),
                    border: InputBorder.none,
                    // static grey baseline (border-bottom: 1px #515151)
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppPalette.border(Color(0xFF515151)), width: 1)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppPalette.border(Color(0xFF515151)), width: 1)),
                  ),
                ),
                // ===== the wave bar (expands from center) =====
                SizedBox(
                  height: 2,
                  width: _width,
                  child: Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                      height: 2,
                      width: _isFocused ? _width : 0,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ===== the floating per-character label =====
          Positioned(
            left: 5,
            top: 24,
            child: IgnorePointer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.label.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                    // stagger each char like transition-delay: index * .05s
                    transform: Matrix4.translationValues(
                      0,
                      floated ? -20 : 0,
                      0,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                      style: TextStyle(
                        fontSize: floated ? 14 : 18,
                        color: floated ? _accent : AppPalette.fg(Color(0xFF999999)),
                      ),
                      child: Text(widget.label[i]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}