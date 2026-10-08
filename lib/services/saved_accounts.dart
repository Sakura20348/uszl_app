import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/api/uzsl_api.dart';

/// How a saved account logs in again
enum LoginMethod { password, google, apple, phone }

/// An account used on this phone, shown on the "Saved accounts" screen after logging out (like
/// Instagram). Only what is needed to show and pick it: never a password or a token.
class SavedAccount {
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatar;
  final LoginMethod method;
  final DateTime lastUsed;

  const SavedAccount({required this.id, this.name, this.email, this.phone, this.avatar, required this.method, required this.lastUsed});

  /// Big line: the name, else the email or phone
  String get title => (name?.trim().isNotEmpty ?? false) ? name!.trim() : (email ?? phone ?? '');
  /// Small line: the email or phone (empty when it's already the title)
  String get subtitle {
    final login = method == LoginMethod.phone ? (phone ?? email) : (email ?? phone);
    return login == null || login == title ? '' : login;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone, 'avatar': avatar, 'method': method.name, 'lastUsed': lastUsed.toIso8601String(),
  };

  factory SavedAccount.fromJson(Map<String, dynamic> j) => SavedAccount(
    id: j['id'] as int, name: j['name'] as String?, email: j['email'] as String?, phone: j['phone'] as String?, avatar: j['avatar'] as String?,
    method: LoginMethod.values.asNameMap()[j['method']] ?? LoginMethod.password,
    lastUsed: DateTime.tryParse(j['lastUsed'] as String? ?? '') ?? DateTime(2000),
  );
}

class SavedAccounts {
  SavedAccounts._();

  /// Kept when logging out (see AccountService._keep)
  static const String key = 'saved_accounts';
  static const int _max = 5;

  /// Newest first
  static Future<List<SavedAccount>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final list = <SavedAccount>[];
    for (final raw in prefs.getStringList(key) ?? const <String>[]) {
      try {
        list.add(SavedAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {/* an unreadable entry is skipped */}
    }
    return list..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
  }

  static Future<void> _write(List<SavedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, [for (final a in accounts.take(_max)) jsonEncode(a.toJson())]);
  }

  /// After a login: [me] is the server's profile. An account already saved moves to the top;
  /// its method changes to the one just used.
  static Future<void> remember(Map<String, dynamic> me, LoginMethod method) async {
    final id = me['id'] as int;
    final accounts = (await all()).where((a) => a.id != id).toList();
    final name = (me['fullName'] as String?)?.trim();
    accounts.insert(0, SavedAccount(
      id: id, name: (name?.isEmpty ?? true) ? null : name, email: me['email'] as String?, phone: me['phone'] as String?,
      avatar: UzslApi.mediaUrl(me['avatar'] as String?), method: method, lastUsed: DateTime.now(),
    ));
    await _write(accounts);
  }

  /// The name and photo can change after the login (profile screen): refreshed when logging out
  static Future<void> update(int id, {String? name, String? avatar}) async {
    final accounts = await all();
    final i = accounts.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final a = accounts[i];
    accounts[i] = SavedAccount(
      id: a.id, name: (name?.trim().isNotEmpty ?? false) ? name!.trim() : a.name, email: a.email, phone: a.phone,
      avatar: avatar ?? a.avatar, method: a.method, lastUsed: a.lastUsed,
    );
    await _write(accounts);
  }

  static Future<void> remove(int id) async => _write((await all()).where((a) => a.id != id).toList());
}
