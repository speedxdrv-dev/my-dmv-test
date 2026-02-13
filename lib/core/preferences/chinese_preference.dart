import 'package:shared_preferences/shared_preferences.dart';

const String _kIsTraditional = 'chinese_is_traditional';

/// 简繁偏好持久化
class ChinesePreference {
  ChinesePreference._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 加载是否使用繁体
  static Future<bool> loadIsTraditional() async {
    try {
      final prefs = await _instance;
      return prefs.getBool(_kIsTraditional) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 保存是否使用繁体
  static Future<void> saveIsTraditional(bool value) async {
    try {
      final prefs = await _instance;
      await prefs.setBool(_kIsTraditional, value);
    } catch (_) {
      // 忽略存储失败
    }
  }
}
