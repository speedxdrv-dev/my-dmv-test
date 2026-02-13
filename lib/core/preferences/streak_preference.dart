import 'package:shared_preferences/shared_preferences.dart';

const String _kLastLoginDate = 'streak_last_login_date';
const String _kStreakCount = 'streak_count';

/// 连续打卡记录
class StreakPreference {
  StreakPreference._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 获取今日日期字符串 yyyy-MM-dd
  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 获取昨天日期字符串
  static String _yesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  /// 检查并更新打卡，返回当前连续天数
  static Future<int> checkAndUpdateStreak() async {
    try {
      final prefs = await _instance;
      final lastDate = prefs.getString(_kLastLoginDate);
      final count = prefs.getInt(_kStreakCount) ?? 0;
      final today = _todayString();
      final yesterday = _yesterdayString();

      int newCount;
      if (lastDate == null) {
        // 第一次打开
        newCount = 1;
      } else if (lastDate == today) {
        // 今天已记录
        newCount = count;
        return newCount;
      } else if (lastDate == yesterday) {
        // 昨天打过，连续
        newCount = count + 1;
      } else {
        // 断签，重新开始
        newCount = 1;
      }

      await prefs.setString(_kLastLoginDate, today);
      await prefs.setInt(_kStreakCount, newCount);
      return newCount;
    } catch (_) {
      return 1;
    }
  }

  /// 仅读取当前 streak（不更新）
  static Future<int> loadStreakCount() async {
    try {
      final prefs = await _instance;
      return prefs.getInt(_kStreakCount) ?? 1;
    } catch (_) {
      return 1;
    }
  }
}
