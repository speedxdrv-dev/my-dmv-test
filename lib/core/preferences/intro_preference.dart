import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kIntroSeen = 'intro_seen';

/// 介绍页是否已看过
/// Web 端：每次页面加载都需先看介绍（避免直接跳转）
/// 移动端：使用 SharedPreferences，持久保存
class IntroPreference {
  IntroPreference._();

  static SharedPreferences? _prefs;
  static bool _webIntroSeenThisLoad = false;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 是否已看过介绍页
  static Future<bool> loadIntroSeen() async {
    if (kIsWeb) {
      return _webIntroSeenThisLoad;
    }
    try {
      final prefs = await _instance;
      return prefs.getBool(_kIntroSeen) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 标记介绍页已看过
  static Future<void> saveIntroSeen(bool value) async {
    if (kIsWeb) {
      _webIntroSeenThisLoad = value;
    }
    try {
      final prefs = await _instance;
      await prefs.setBool(_kIntroSeen, value);
    } catch (_) {}
  }

  /// 退出登录时重置，下次启动视为未注册用户
  static Future<void> clear() async {
    if (kIsWeb) {
      _webIntroSeenThisLoad = false;
    }
    try {
      final prefs = await _instance;
      await prefs.remove(_kIntroSeen);
    } catch (_) {}
  }
}
