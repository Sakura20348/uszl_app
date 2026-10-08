import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UzSL API (signlang/backend).
///
/// By default the app talks to [devServer], the backend on the development laptop. In debug builds,
/// when it can't be reached, the app also tries [devServerWifi] and keeps using the one that answers:
/// - phone on USB: `adb reverse tcp:8000 tcp:8000` makes localhost on the phone reach the laptop
/// - phone on the same Wi-Fi: the laptop's Wi-Fi address (`hostname -I`)
/// Another server for one run (e.g. the Android emulator, or production):
///   flutter run --dart-define=API_URL=http://10.0.2.2:8000
class UzslApi {
  static const String devServer = 'http://localhost:8000';
  /// The laptop's Wi-Fi address; update it when the laptop gets a new one.
  /// The backend must run with: uv run fastapi dev app/main.py --host 0.0.0.0
  static const String devServerWifi = 'http://192.168.1.122:8000';
  /// The public server (backend/deploy). Release builds use it; change it to your API domain.
  static const String productionServer = 'https://api.uzsl.uz';
  static const String _configured = String.fromEnvironment('API_URL', defaultValue: kReleaseMode ? productionServer : devServer);
  static String _base = _configured;
  /// The server in use (may switch to [devServerWifi] in debug builds, see above)
  static String get baseUrl => _base;
  static const Duration _timeout = Duration(seconds: 20);
  // A local server that doesn't answer within this is treated as unreachable, so the other one is tried quickly
  static const Duration _probeTimeout = Duration(seconds: 5);
  static final http.Client _client = http.Client();

  static const _accessKey = 'api_access_token';
  static const _refreshKey = 'api_refresh_token';

  // ======================== session ========================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey) != null;
  }

  static Future<void> _saveTokens(Map<String, dynamic> tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, tokens['accessToken'] as String);
    await prefs.setString(_refreshKey, tokens['refreshToken'] as String);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  // ======================== requests ========================
  static Uri _uri(String path, [Map<String, String>? query, String? base]) => Uri.parse('${base ?? _base}/api/v1$path').replace(queryParameters: query);

  static Future<http.Response> _sendTo(String base, String method, String path, Object? body, Map<String, String>? query, String? token, Duration timeout) {
    final headers = {'Accept': 'application/json', if (body != null) 'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
    final request = http.Request(method, _uri(path, query, base))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    return _client.send(request).then(http.Response.fromStream).timeout(timeout);
  }

  static Future<http.Response> _send(String method, String path, {Object? body, Map<String, String>? query, String? token}) async {
    final local = kDebugMode && _configured == devServer;
    try {
      return await _sendTo(_base, method, path, body, query, token, local ? _probeTimeout : _timeout);
    } catch (e) {
      if (!local) rethrow;
      // Debug: the laptop may be reachable the other way (USB <-> Wi-Fi)
      final other = _base == devServer ? devServerWifi : devServer;
      final response = await _sendTo(other, method, path, body, query, token, _probeTimeout);
      debugPrint('API: $_base not reachable, using $other');
      _base = other;
      return response;
    }
  }

  // One refresh at a time, shared by requests that got 401 together
  static Future<bool>? _refreshing;

  static Future<bool> _refresh() {
    return _refreshing ??= () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString(_refreshKey);
        if (refreshToken == null) return false;
        final response = await _send('POST', '/auth/refresh', body: {'refreshToken': refreshToken});
        if (response.statusCode != 200) return false;
        await _saveTokens(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
        return true;
      } catch (_) {
        return false;
      }
    }().whenComplete(() => _refreshing = null);
  }

  /// JSON from the API; throws [ApiException] with the server's message.
  /// [auth]: needs a login. [withLogin]: public, but sends the login when there is one
  /// (e.g. courses with the learner's progress).
  static Future<dynamic> _request(String method, String path, {Object? body, Map<String, String>? query, bool auth = false, bool withLogin = false}) async {
    Future<http.Response> send() async {
      String? token;
      if (auth || withLogin) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(_accessKey);
        if (token == null && auth) throw const ApiException(401, 'Not logged in');
      }
      return _send(method, path, body: body, query: query, token: token);
    }

    http.Response response;
    try {
      response = await send();
      // Access token expired: refresh once and repeat; if that fails the session is over
      if (response.statusCode == 401 && auth) {
        if (await _refresh()) {
          response = await send();
        } else {
          await logout();
        }
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      // Keep the real reason in the log (refused, timed out, blocked...)
      debugPrint('API $method $path failed: $e');
      throw const ApiException(0, 'network');
    }

    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 400) throw ApiException(response.statusCode, _errorMessage(text, response.statusCode));
    return text.isEmpty ? null : jsonDecode(text);
  }

  // FastAPI errors: {"detail": "text"} or {"detail": [{"msg": "..."}]}
  static String _errorMessage(String text, int status) {
    try {
      final detail = (jsonDecode(text) as Map<String, dynamic>)['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty && detail.first is Map) return (detail.first as Map)['msg']?.toString() ?? 'HTTP $status';
    } catch (_) {
      // not JSON
    }
    return 'HTTP $status';
  }

  // ======================== login with SMS code ========================
  /// Sends a login code to the phone. Returns the code itself while the server has no SMS
  /// provider (OTP_DEBUG), so it can be shown in debug builds; null otherwise.
  static Future<String?> requestCode(String phone) async {
    final data = await _request('POST', '/auth/otp/request', body: {'phone': phone});
    return (data as Map<String, dynamic>)['debugCode'] as String?;
  }

  /// Checks the code and logs in (creates the account if the number is new).
  static Future<void> verifyCode(String phone, String code) async {
    // Sent with the login (if any): an email account gets this phone added instead of a second account
    final data = await _request('POST', '/auth/otp/verify', body: {'phone': phone, 'code': code}, withLogin: true);
    await _saveTokens(data as Map<String, dynamic>);
  }

  // ======================== login with Firebase (email/password) ========================
  /// Trades a Firebase ID token for this API's login; creates the account the first time.
  static Future<void> firebaseLogin(String idToken, {String? fullName}) async {
    final data = await _request('POST', '/auth/firebase', body: {'idToken': idToken, 'fullName': ?fullName});
    await _saveTokens(data as Map<String, dynamic>);
  }

  // ======================== push notification devices ========================
  /// Tells the server where to send push notifications for the logged-in user.
  static Future<void> registerDevice(String token, String platform) =>
      _request('POST', '/app/devices', body: {'token': token, 'platform': platform}, auth: true);

  /// Time spent in a part of the app outside lessons: dictionary, translator, dataset, other.
  static Future<void> reportSession(String source, DateTime startedAt, DateTime endedAt) async {
    if (!await isLoggedIn()) return;
    try {
      await _request('POST', '/app/activity-sessions', auth: true, body: {
        'source': source,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Activity time not sent: $e');
    }
  }

  /// The app was closed or logged out: the dashboard shows the user offline right away
  /// (the next request after it shows them online again).
  static Future<void> goOffline() async {
    if (!await isLoggedIn()) return;
    try {
      await _request('POST', '/app/presence/offline', auth: true);
    } catch (e) {
      // Not important enough to bother anyone: the status turns offline by itself after 2 minutes
      debugPrint('Offline status not sent: $e');
    }
  }

  /// Stops push notifications to this phone (on log out).
  static Future<void> removeDevice(String token) => _request('DELETE', '/app/devices/${Uri.encodeComponent(token)}', auth: true);

  // ======================== notifications ========================
  static Future<List<AppNotification>> notifications({int limit = 50}) async {
    final data = await _request('GET', '/app/notifications', query: {'limit': '$limit'}, auth: true) as Map<String, dynamic>;
    return (data['items'] as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Newest unread notifications and how many are unread in total.
  static Future<({List<AppNotification> items, int total})> unreadNotifications({int limit = 10}) async {
    final data = await _request('GET', '/app/notifications', query: {'unread': 'true', 'limit': '$limit'}, auth: true) as Map<String, dynamic>;
    return (
      items: (data['items'] as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList(),
      total: data['total'] as int,
    );
  }

  static Future<int> unreadCount() async {
    final data = await _request('GET', '/app/notifications', query: {'unread': 'true', 'limit': '1'}, auth: true) as Map<String, dynamic>;
    return data['total'] as int;
  }

  static Future<void> markRead(int id) => _request('POST', '/app/notifications/$id/read', auth: true);

  static Future<void> markAllRead() => _request('POST', '/app/notifications/read-all', auth: true);

  /// Full URL for files the API stores ("/media/..."); other paths are returned unchanged.
  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return path.startsWith('/media/') ? '$baseUrl$path' : path;
  }

  // ======================== profile ========================
  /// Saves the name (and photo) on the server. [imagePath]: a local file to upload,
  /// '' to remove the photo, null to keep it.
  static Future<void> updateProfile({required String fullName, String? imagePath}) async {
    final body = <String, dynamic>{'fullName': fullName};
    if (imagePath != null) body['avatar'] = imagePath.isEmpty ? null : await uploadFile(imagePath);
    await _request('PATCH', '/app/profile', body: body, auth: true);
  }

  /// Onboarding answers, name and language (see OnboardingAnswers); only the given fields change.
  /// Deletes the account and everything saved for it on the server; it can't be undone.
  static Future<void> deleteAccount() => _request('DELETE', '/app/profile', auth: true);

  static Future<void> updateOnboarding(Map<String, dynamic> profile) => _request('PATCH', '/app/profile', body: profile, auth: true);

  /// Uploads a photo / video / audio file; returns the stored path for the API's file fields.
  static Future<String> uploadFile(String filePath) async {
    Future<http.StreamedResponse> send() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessKey);
      if (token == null) throw const ApiException(401, 'Not logged in');
      final request = http.MultipartRequest('POST', _uri('/app/uploads'))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', filePath, contentType: _mediaType(filePath)));
      return _client.send(request).timeout(const Duration(seconds: 60));
    }

    http.Response response;
    try {
      response = await http.Response.fromStream(await send());
      if (response.statusCode == 401 && await _refresh()) response = await http.Response.fromStream(await send());
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('API upload failed: $e');
      throw const ApiException(0, 'network');
    }
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 400) throw ApiException(response.statusCode, _errorMessage(text, response.statusCode));
    return (jsonDecode(text) as Map<String, dynamic>)['path'] as String;
  }

  static MediaType _mediaType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    const types = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'webp': 'image/webp', 'gif': 'image/gif',
      'mp4': 'video/mp4', 'mov': 'video/quicktime', 'webm': 'video/webm', 'm4a': 'audio/mp4', 'mp3': 'audio/mpeg', 'aac': 'audio/aac',
    };
    return MediaType.parse(types[ext] ?? 'application/octet-stream');
  }

  // ======================== account ========================
  /// The logged-in account: id, name, phone/email
  static Future<Map<String, dynamic>> me() async => await _request('GET', '/auth/me', auth: true) as Map<String, dynamic>;

  /// Built-in lessons ("alp_0", ...) this account has completed
  static Future<List<String>> completedBuiltinLessons() async =>
      (await _request('GET', '/app/builtin-lessons/completed', auth: true) as List).cast<String>();

  // ======================== learning statistics ========================
  static Future<ApiStats> stats() async =>
      ApiStats.fromJson(await _request('GET', '/app/stats', auth: true) as Map<String, dynamic>);

  /// Minutes per day (bars) and the activity calendar, for 'week', 'month' or 'year'
  static Future<ApiActivity> activity(String period) async =>
      ApiActivity.fromJson(await _request('GET', '/app/activity', query: {'period': period}, auth: true) as Map<String, dynamic>);

  /// 5, 10, 15 or 20 minutes
  static Future<void> setDailyGoal(int minutes) => _request('PATCH', '/app/profile', body: {'dailyGoalMinutes': minutes}, auth: true);

  // ======================== textbooks from the dashboard ========================
  // ===== dictionary (signs made in the dashboard) =====
  static Future<List<ApiCategory>> categories() async {
    final data = await _request('GET', '/app/categories') as List;
    return data.map((e) => ApiCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// One page of published signs; [query] searches Uzbek, Russian and English, [category] is a category slug.
  static Future<({List<ApiSign> items, int total})> signs({String? query, String? category, int limit = 200, int offset = 0}) async {
    final data = await _request('GET', '/app/signs', query: {
      'limit': '$limit', 'offset': '$offset',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'category': ?category,
    }) as Map<String, dynamic>;
    return (items: (data['items'] as List).map((e) => ApiSign.fromJson(e as Map<String, dynamic>)).toList(), total: data['total'] as int? ?? 0);
  }

  /// Every published sign (pages of 200).
  static Future<List<ApiSign>> allSigns({String? category}) async {
    final all = <ApiSign>[];
    while (true) {
      final page = await signs(category: category, offset: all.length);
      all.addAll(page.items);
      if (page.items.isEmpty || all.length >= page.total) return all;
    }
  }

  /// [lang]: app language the texts are picked in (Uzbek when not translated)
  static Future<ApiSignDetail> sign(int id, {String lang = 'uz'}) async {
    final data = await _request('GET', '/app/signs/$id', withLogin: true) as Map<String, dynamic>;
    return ApiSignDetail.fromJson(data, lang: lang);
  }

  static Future<List<ApiCourse>> courses() async {
    final data = await _request('GET', '/app/courses', withLogin: true) as List;
    return data.map((e) => ApiCourse.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<ApiLesson>> courseLessons(int courseId) async {
    final data = await _request('GET', '/app/courses/$courseId/lessons', withLogin: true) as List;
    return data.map((e) => ApiLesson.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// [lang]: app language the texts are picked in (Uzbek when not translated)
  static Future<ApiLessonDetail> lesson(int lessonId, {String lang = 'uz'}) async {
    final data = await _request('GET', '/app/lessons/$lessonId', withLogin: true) as Map<String, dynamic>;
    return ApiLessonDetail.fromJson(data, lang: lang);
  }

  /// Starts playing a lesson; returns the attempt id.
  static Future<int> startAttempt(int lessonId) async {
    final data = await _request('POST', '/app/lessons/$lessonId/attempts', auth: true) as Map<String, dynamic>;
    return data['id'] as int;
  }

  /// Checks one answer on the server (see AnswerIn in the backend for the formats).
  static Future<AnswerResult> answer(int attemptId, int exerciseId, Map<String, dynamic> answer, {String lang = 'uz'}) async {
    final data = await _request('POST', '/app/attempts/$attemptId/answers', body: {'exerciseId': exerciseId, 'answer': answer}, auth: true);
    return AnswerResult.fromJson(data as Map<String, dynamic>, lang: lang);
  }

  static Future<LessonResult> finish(int attemptId) async {
    final data = await _request('POST', '/app/attempts/$attemptId/finish', auth: true);
    return LessonResult.fromJson(data as Map<String, dynamic>);
  }

  // ======================== the app's own lessons ========================
  /// The server's lesson for a built-in lesson ("alp_0"); it has exercises when the dashboard made them.
  static Future<ApiLesson> builtinLesson(String key) async {
    final data = await _request('GET', '/app/builtin-lessons/$key', withLogin: true);
    return ApiLesson.fromJson(data as Map<String, dynamic>);
  }

  /// Result of a lesson played with the app's own screens ("alp_0", "num_3", ...).
  static Future<LessonResult> completeBuiltinLesson(String key, {required int correct, required int wrong, required int durationSeconds}) async {
    final data = await _request('POST', '/app/builtin-lessons/$key/complete',
        body: {'correct': correct, 'wrong': wrong, 'durationSeconds': durationSeconds}, auth: true);
    return LessonResult.fromJson(data as Map<String, dynamic>);
  }
}

class ApiException implements Exception {
  /// 0 = the server couldn't be reached
  final int status;
  final String message;
  const ApiException(this.status, this.message);

  bool get isNetwork => status == 0;

  @override
  String toString() => 'ApiException($status): $message';
}

/// A notification from the dashboard (news, reminder, system) or the app itself (achievement).
class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  bool isRead;

  AppNotification({required this.id, required this.type, required this.title, required this.body, required this.data, required this.createdAt, required this.isRead});

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as int,
    type: json['type'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    isRead: json['isRead'] as bool,
  );
}


/// Dashboard texts come in Uzbek (`key`) and optionally Russian / English
/// (`keyRu`, `keyEn`); picks the app language, falling back to Uzbek.
String? pickLang(Map<String, dynamic> j, String key, String lang) {
  final suffix = switch (lang) { 'ru' => 'Ru', 'en' => 'En', _ => null };
  final translated = suffix == null ? null : j['$key$suffix'] as String?;
  return (translated?.trim().isNotEmpty ?? false) ? translated : j[key] as String?;
}

String _pick(String uz, String? ru, String? en, String lang) {
  final translated = switch (lang) { 'ru' => ru, 'en' => en, _ => null };
  return (translated?.trim().isNotEmpty ?? false) ? translated! : uz;
}

// ======================== textbooks and lessons ========================
/// A textbook from the dashboard
class ApiCourse {
  final int id;
  final String title;
  final String? titleRu;
  final String? titleEn;
  final String slug;
  final String? icon;
  final String unitLabel;
  final int lessonCount;
  final int completedLessons;
  final String? subtitle;
  final String? description;
  final String? descriptionRu;
  final String? descriptionEn;

  ApiCourse({required this.id, required this.title, this.titleRu, this.titleEn, required this.slug, this.icon, required this.unitLabel, required this.lessonCount, required this.completedLessons, this.subtitle, this.description,
    this.descriptionRu, this.descriptionEn});

  factory ApiCourse.fromJson(Map<String, dynamic> j) => ApiCourse(
    id: j['id'] as int, title: j['title'] as String, titleRu: j['titleRu'] as String?, titleEn: j['titleEn'] as String?,
    slug: j['slug'] as String, icon: j['icon'] as String?, unitLabel: j['unitLabel'] as String? ?? '',
    lessonCount: j['lessonCount'] as int? ?? 0, completedLessons: j['completedLessons'] as int? ?? 0,
    subtitle: j['subtitle'] as String?, description: j['description'] as String?,
    descriptionRu: j['descriptionRu'] as String?, descriptionEn: j['descriptionEn'] as String?,
  );

  /// Title in the app language; Uzbek when there is no translation
  String titleFor(String lang) => _pick(title, titleRu, titleEn, lang);

  String? descriptionFor(String lang) => description == null ? null : _pick(description!, descriptionRu, descriptionEn, lang);
}

class ApiLesson {
  final int id;
  final String title;
  final String? titleRu;
  final String? titleEn;
  final String? description;
  final String? descriptionRu;
  final String? descriptionEn;
  final int durationMinutes;
  final int exerciseCount;
  /// null = not started, 'in_progress', 'completed'
  final String? status;
  final int? bestAccuracy;
  final String? thumbnail;
  /// easy | medium | hard
  final String difficulty;
  final int signCount;

  ApiLesson({required this.id, required this.title, this.titleRu, this.titleEn, this.description, this.descriptionRu, this.descriptionEn, required this.durationMinutes, required this.exerciseCount, this.status, this.bestAccuracy,
    this.thumbnail, this.difficulty = 'easy', this.signCount = 0});

  factory ApiLesson.fromJson(Map<String, dynamic> j) => ApiLesson(
    id: j['id'] as int, title: j['title'] as String, titleRu: j['titleRu'] as String?, titleEn: j['titleEn'] as String?,
    description: j['description'] as String?, descriptionRu: j['descriptionRu'] as String?, descriptionEn: j['descriptionEn'] as String?,
    durationMinutes: j['durationMinutes'] as int? ?? 5, exerciseCount: j['exerciseCount'] as int? ?? 0,
    status: j['status'] as String?, bestAccuracy: j['bestAccuracy'] as int?,
    thumbnail: UzslApi.mediaUrl(j['thumbnail'] as String?), difficulty: j['difficulty'] as String? ?? 'easy', signCount: j['signCount'] as int? ?? 0,
  );

  /// Name in the app language; Uzbek when there is no translation
  String titleFor(String lang) => _pick(title, titleRu, titleEn, lang);

  String? descriptionFor(String lang) => description == null ? null : _pick(description!, descriptionRu, descriptionEn, lang);
}

class ApiOption {
  final int id;
  final String? text;
  final String? image;
  final String? signVideo;

  ApiOption({required this.id, this.text, this.image, this.signVideo});

  factory ApiOption.fromJson(Map<String, dynamic> j, {String lang = 'uz'}) => ApiOption(
    id: j['id'] as int, text: pickLang(j, 'text', lang), image: UzslApi.mediaUrl(j['image'] as String?), signVideo: UzslApi.mediaUrl(j['signVideo'] as String?),
  );
}

/// One exercise; the correct answer is not included (the server checks answers)
class ApiExercise {
  final int id;
  /// chooseText | chooseImage | matching | order
  final String type;
  final String? prompt;
  final String? signVideo;
  final List<ApiOption> options;

  ApiExercise({required this.id, required this.type, this.prompt, this.signVideo, required this.options});

  factory ApiExercise.fromJson(Map<String, dynamic> j, {String lang = 'uz'}) => ApiExercise(
    id: j['id'] as int, type: j['type'] as String, prompt: pickLang(j, 'prompt', lang), signVideo: UzslApi.mediaUrl(j['signVideo'] as String?),
    options: (j['options'] as List).map((e) => ApiOption.fromJson(e as Map<String, dynamic>, lang: lang)).toList(),
  );
}

class ApiLessonDetail {
  final int id;
  final String title;
  final List<ApiExercise> exercises;

  ApiLessonDetail({required this.id, required this.title, required this.exercises});

  factory ApiLessonDetail.fromJson(Map<String, dynamic> j, {String lang = 'uz'}) => ApiLessonDetail(
    id: j['id'] as int, title: pickLang(j, 'title', lang) ?? '',
    exercises: (j['exercises'] as List).map((e) => ApiExercise.fromJson(e as Map<String, dynamic>, lang: lang)).toList(),
  );
}

class AnswerResult {
  final bool isCorrect;
  final String? explanation;
  final int? correctOptionId;
  final List<int>? correctOrder;

  AnswerResult({required this.isCorrect, this.explanation, this.correctOptionId, this.correctOrder});

  factory AnswerResult.fromJson(Map<String, dynamic> j, {String lang = 'uz'}) => AnswerResult(
    isCorrect: j['isCorrect'] as bool, explanation: pickLang(j, 'explanation', lang), correctOptionId: j['correctOptionId'] as int?,
    correctOrder: (j['correctOrder'] as List?)?.cast<int>(),
  );
}

class LessonResult {
  final int accuracy;
  final int correct;
  final int total;
  final int xpEarned;
  final bool passed;
  final int totalXp;
  final int level;
  final int streak;
  final List<String> unlockedAchievements;

  LessonResult({required this.accuracy, required this.correct, required this.total, required this.xpEarned, required this.passed,
    required this.totalXp, required this.level, required this.streak, required this.unlockedAchievements});

  factory LessonResult.fromJson(Map<String, dynamic> j) {
    final attempt = j['attempt'] as Map<String, dynamic>;
    final stats = j['stats'] as Map<String, dynamic>;
    return LessonResult(
      accuracy: attempt['accuracy'] as int, correct: attempt['correctCount'] as int, total: attempt['totalCount'] as int,
      xpEarned: attempt['xpEarned'] as int, passed: j['passed'] as bool,
      totalXp: stats['totalXp'] as int, level: stats['level'] as int, streak: stats['currentStreak'] as int,
      unlockedAchievements: (j['unlockedAchievements'] as List).map((a) => (a as Map)['title'] as String).toList(),
    );
  }
}

// ======================== statistics ========================
class ApiStats {
  final int totalXp, level, currentStreak, longestStreak, signsLearned, lessonsCompleted;
  final int todayMinutes, dailyGoalMinutes, lessonsToday, xpToday;
  /// 0-100; null before the first answer
  final int? accuracy, accuracyToday;
  /// Monday first
  final List<bool> weekDays;

  ApiStats({required this.totalXp, required this.level, required this.currentStreak, required this.longestStreak,
    required this.signsLearned, required this.lessonsCompleted, required this.todayMinutes, required this.dailyGoalMinutes,
    required this.lessonsToday, required this.xpToday, this.accuracy, this.accuracyToday, required this.weekDays});

  factory ApiStats.fromJson(Map<String, dynamic> j) => ApiStats(
    totalXp: j['totalXp'] as int, level: j['level'] as int, currentStreak: j['currentStreak'] as int, longestStreak: j['longestStreak'] as int,
    signsLearned: j['signsLearned'] as int, lessonsCompleted: j['lessonsCompleted'] as int, todayMinutes: j['todayMinutes'] as int,
    dailyGoalMinutes: j['dailyGoalMinutes'] as int, lessonsToday: j['lessonsToday'] as int? ?? 0, xpToday: j['xpToday'] as int? ?? 0,
    accuracy: j['accuracy'] as int?, accuracyToday: j['accuracyToday'] as int?,
    weekDays: (j['weekDays'] as List?)?.cast<bool>() ?? List.filled(7, false),
  );
}

class ApiActivity {
  /// Average learning minutes per day for each bar: 7 days, 4 weeks or 12 months
  final List<int> bars;
  /// Minutes per time slot (8 rows, 22:00 at the top) and weekday (7 columns, Monday first)
  final List<List<int>> heatmap;
  final int weeks;

  ApiActivity({required this.bars, required this.heatmap, required this.weeks});

  factory ApiActivity.fromJson(Map<String, dynamic> j) => ApiActivity(
    bars: (j['bars'] as List).map((b) => (b as Map)['minutes'] as int).toList(),
    heatmap: (j['heatmap'] as List).map((row) => (row as List).cast<int>()).toList(),
    weeks: j['weeks'] as int,
  );
}

class ApiCategory {
  final int id;
  final String slug;
  final String name;
  final String? nameRu;
  final String? nameEn;
  final int signCount;
  final String? unitLabel;
  /// The dashboard's icon, e.g. "solar:pills-linear"
  final String? icon;

  ApiCategory({required this.id, required this.slug, required this.name, this.nameRu, this.nameEn, required this.signCount, this.unitLabel, this.icon});

  factory ApiCategory.fromJson(Map<String, dynamic> j) => ApiCategory(
    id: j['id'] as int, slug: j['slug'] as String, name: j['name'] as String,
    nameRu: j['nameRu'] as String?, nameEn: j['nameEn'] as String?, signCount: j['signCount'] as int? ?? 0, unitLabel: j['unitLabel'] as String?,
    icon: j['icon'] as String?,
  );

  String nameFor(String lang) => _pick(name, nameRu, nameEn, lang);
}

/// A sign as listed in the dictionary
class ApiSign {
  final int id;
  final String word;
  final String? transcription;
  final String? transcriptionRu;
  final String? transcriptionEn;
  final String? translationRu;
  final String? translationEn;
  final String kind;
  final String? thumbnail;

  ApiSign({required this.id, required this.word, this.transcription, this.transcriptionRu, this.transcriptionEn, this.translationRu, this.translationEn, required this.kind, this.thumbnail});

  factory ApiSign.fromJson(Map<String, dynamic> j) => ApiSign(
    id: j['id'] as int, word: j['word'] as String, transcription: j['transcription'] as String?,
    transcriptionRu: j['transcriptionRu'] as String?, transcriptionEn: j['transcriptionEn'] as String?,
    translationRu: j['translationRu'] as String?, translationEn: j['translationEn'] as String?,
    kind: j['kind'] as String? ?? 'word', thumbnail: UzslApi.mediaUrl(j['thumbnail'] as String?),
  );

  /// The word in the app's language (Uzbek is the sign's own word)
  String wordFor(String lang) => _pick(word, translationRu, translationEn, lang);

  /// Syllables in [lang]; null when that language has none
  String? ownTranscription(String lang) {
    final text = switch (lang) { 'ru' => transcriptionRu, 'en' => transcriptionEn, _ => transcription };
    return (text?.trim().isNotEmpty ?? false) ? text : null;
  }

  /// Syllables in [lang], else the Uzbek ones
  String? transcriptionFor(String lang) => ownTranscription(lang) ?? ownTranscription('uz');
}

/// A sign with its videos and explanations
class ApiSignDetail extends ApiSign {
  final String? meaning;
  final String? handShape;
  final String? movement;
  final String? exampleSentence;
  final String? exampleVideo;
  final List<String> videos;
  final List<ApiCategory> categories;
  final List<ApiSign> related;

  ApiSignDetail({
    required super.id, required super.word, super.transcription, super.transcriptionRu, super.transcriptionEn, super.translationRu, super.translationEn, required super.kind, super.thumbnail,
    this.meaning, this.handShape, this.movement, this.exampleSentence, this.exampleVideo,
    this.videos = const [], this.categories = const [], this.related = const [],
  });

  /// Meaning, hand shape, movement and example are picked in [lang]
  factory ApiSignDetail.fromJson(Map<String, dynamic> j, {String lang = 'uz'}) {
    final brief = ApiSign.fromJson(j);
    return ApiSignDetail(
      id: brief.id, word: brief.word, transcription: brief.transcription, transcriptionRu: brief.transcriptionRu, transcriptionEn: brief.transcriptionEn, translationRu: brief.translationRu, translationEn: brief.translationEn,
      kind: brief.kind, thumbnail: brief.thumbnail,
      meaning: pickLang(j, 'meaning', lang), handShape: pickLang(j, 'handShape', lang), movement: pickLang(j, 'movement', lang),
      exampleSentence: pickLang(j, 'exampleSentence', lang), exampleVideo: UzslApi.mediaUrl(j['exampleVideo'] as String?),
      videos: [for (final v in (j['videos'] as List? ?? [])) ?UzslApi.mediaUrl((v as Map<String, dynamic>)['video'] as String?)],
      categories: [for (final c in (j['categories'] as List? ?? [])) ApiCategory.fromJson({...c as Map<String, dynamic>, 'signCount': 0})],
      related: [for (final r in (j['related'] as List? ?? [])) ApiSign.fromJson(r as Map<String, dynamic>)],
    );
  }
}
