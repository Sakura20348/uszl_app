import 'package:flutter/foundation.dart';
import 'package:signlang/components/profile/nameProfile/nameStore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'uzsl_api.dart';

class ApiService {
  /// Saves the profile on the server (UzSL API, see [UzslApi]).
  ///
  /// [name] and [lastName] are stored together as the full name. [image] is a local file path
  /// to upload, or '' for no photo. The phone number is the login itself, so it isn't changed here.
  /// Returns false when not logged in or the server can't be reached; the local copy stays saved.
  static Future<bool> updateProfile({
    required String name,
    required String lastName,
    required String phone,
    required String image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingKey, true);
    if (!await UzslApi.isLoggedIn()) return false;
    try {
      await UzslApi.updateProfile(fullName: '$name $lastName'.trim(), imagePath: image);
      await prefs.setBool(_pendingKey, false);
      return true;
    } on ApiException catch (e) {
      debugPrint('Profile not saved on the server (sent on the next start): $e');
      return false;
    }
  }

  static const _pendingKey = 'profile_sync_pending';

  /// Sends a profile saved while the server couldn't be reached (called when the app starts).
  static Future<void> syncPending() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_pendingKey) ?? false)) return;
    await updateProfile(
      name: await NameStorage.load() ?? '',
      lastName: await LastNameStorage.load() ?? '',
      phone: await NumberStorage.load() ?? '',
      image: await ImageStorage.load() ?? '',
    );
  }
}
