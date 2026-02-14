import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../preferences/intro_preference.dart';
import '../preferences/mistakes_preference.dart';
import '../preferences/streak_preference.dart';
import '../user/user_manager.dart';
import '../utils/resources/supabase.dart';

/// 退出登录服务：删除登录状态、本地缓存，视用户为未注册
class LogoutService {
  LogoutService._();

  /// 执行完整登出：清除内存状态、本地缓存、Supabase 会话
  static Future<void> performLogout() async {
    // 1. 优先登出 Supabase，确保 currentUser 立即为 null，后续点击第四章会先跳登录页
    await supabase.auth.signOut();

    // 2. 清除内存中的用户状态（VIP、待访问章节）
    UserManager().clear();

    // 3. 清除本地 SharedPreferences 中的用户相关缓存
    await MistakesPreference.clear();
    await StreakPreference.clear();
    await IntroPreference.clear();

    // 4. 清除图片缓存（题目图片等）
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
  }
}
