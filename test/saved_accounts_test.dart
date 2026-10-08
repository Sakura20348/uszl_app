import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/services/saved_accounts.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('accounts are remembered newest first, without passwords', () async {
    await SavedAccounts.remember({'id': 1, 'email': 'a@x.uz', 'fullName': ''}, LoginMethod.password);
    await SavedAccounts.remember({'id': 2, 'phone': '+998901234567', 'fullName': 'Ali Valiyev'}, LoginMethod.phone);
    var all = await SavedAccounts.all();
    expect(all.map((a) => a.id), [2, 1]);
    expect(all.first.title, 'Ali Valiyev');
    expect(all.first.subtitle, '+998901234567');
    expect(all.last.title, 'a@x.uz'); // no name: the email is the title
    expect(all.last.subtitle, '');
    // only these fields are stored: no password, no token
    final stored = jsonDecode((await SharedPreferences.getInstance()).getStringList(SavedAccounts.key)!.first) as Map<String, dynamic>;
    expect(stored.keys.toSet(), {'id', 'name', 'email', 'phone', 'avatar', 'method', 'lastUsed'});

    // logging in again moves it to the top, with the method just used
    await SavedAccounts.remember({'id': 1, 'email': 'a@x.uz'}, LoginMethod.google);
    all = await SavedAccounts.all();
    expect(all.map((a) => a.id), [1, 2]);
    expect(all.first.method, LoginMethod.google);
  });

  test('name updates, removal, and at most 5', () async {
    for (var i = 1; i <= 7; i++) {
      await SavedAccounts.remember({'id': i, 'email': 'u$i@x.uz'}, LoginMethod.password);
    }
    expect((await SavedAccounts.all()).length, 5);
    expect((await SavedAccounts.all()).first.id, 7);

    await SavedAccounts.update(7, name: 'Madina');
    expect((await SavedAccounts.all()).first.title, 'Madina');

    await SavedAccounts.remove(7);
    expect((await SavedAccounts.all()).any((a) => a.id == 7), isFalse);
  });
}
