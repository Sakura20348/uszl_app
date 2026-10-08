import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Turns a recorded sign clip into text.
///
/// TODO: connect the real recognition model / API here (send [clip] and return its text).
/// Until then debug builds return [debugDemoText] so the screen's states can be tried out,
/// and release builds return null ("not recognized").
class SignRecognizer {
  SignRecognizer._();

  static Future<String?> recognize({XFile? clip, required String debugDemoText}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return kDebugMode ? debugDemoText : null;
  }
}
