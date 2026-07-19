import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/history_item.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _kToken = 'userToken';
  static const _kUserInfo = 'userInfo';
  static const _kHistory = '@reading_history';
  static const _kReadingMode = '@reading_mode';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> getToken() async => (await _prefs).getString(_kToken);

  Future<void> setToken(String token) async =>
      (await _prefs).setString(_kToken, token);

  Future<void> setUserInfo(AppUser user) async =>
      (await _prefs).setString(_kUserInfo, jsonEncode(user.toJson()));

  Future<String> getReadingMode() async =>
      (await _prefs).getString(_kReadingMode) ?? 'vertical';

  Future<void> setReadingMode(String mode) async =>
      (await _prefs).setString(_kReadingMode, mode);

  Future<AppUser?> getUser() async {
    final str = (await _prefs).getString(_kUserInfo);
    if (str == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    final p = await _prefs;
    await p.remove(_kToken);
    await p.remove(_kUserInfo);
  }

  Future<List<HistoryItem>> getLocalHistory() async {
    final str = (await _prefs).getString(_kHistory);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(HistoryItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setLocalHistory(List<HistoryItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await (await _prefs).setString(_kHistory, encoded);
  }

  Future<void> pushHistory(HistoryItem item) async {
    var list = await getLocalHistory();
    list = list.where((h) => h.storyId != item.storyId).toList();
    list.insert(0, item);
    if (list.length > 100) list = list.sublist(0, 100);
    await setLocalHistory(list);
  }
}
