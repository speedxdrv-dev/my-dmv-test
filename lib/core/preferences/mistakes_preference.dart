import 'package:shared_preferences/shared_preferences.dart';

const String _kMistakeIds = 'mistakes_question_ids';

/// 错题本持久化
class MistakesPreference {
  MistakesPreference._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 加载所有错题 ID
  static Future<List<String>> loadMistakeIds() async {
    try {
      final prefs = await _instance;
      return prefs.getStringList(_kMistakeIds) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// 添加错题 ID（去重）
  static Future<void> addMistakeId(String id) async {
    try {
      final ids = await loadMistakeIds();
      if (ids.contains(id)) return;
      ids.add(id);
      final prefs = await _instance;
      await prefs.setStringList(_kMistakeIds, ids);
    } catch (_) {}
  }

  /// 移除错题 ID
  static Future<void> removeMistakeId(String id) async {
    try {
      final ids = await loadMistakeIds();
      ids.remove(id);
      final prefs = await _instance;
      await prefs.setStringList(_kMistakeIds, ids);
    } catch (_) {}
  }

  /// 获取错题数量
  static Future<int> getMistakeCount() async {
    final ids = await loadMistakeIds();
    return ids.length;
  }

  /// 退出登录时清空本地错题缓存
  static Future<void> clear() async {
    try {
      final prefs = await _instance;
      await prefs.remove(_kMistakeIds);
    } catch (_) {}
  }
}
