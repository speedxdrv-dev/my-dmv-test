import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../utils/resources/supabase.dart';

/// 全局用户状态管理，存储 VIP、待访问章节等信息
class UserManager extends ChangeNotifier {
  UserManager._();

  static final UserManager _instance = UserManager._();

  factory UserManager() => _instance;

  bool? _isVip;

  bool? get isVip => _isVip;

  /// 退出登录后置为 true，确保点击第四章时先跳登录页（解决 Supabase session 可能未及时清除的问题）
  bool _forceLogin = false;
  bool get forceLogin => _forceLogin;

  void markForceLogin() {
    _forceLogin = true;
    notifyListeners();
  }

  void clearForceLogin() {
    _forceLogin = false;
    notifyListeners();
  }

  /// 登录回跳后待访问的章节（从章节点击跳转登录时设置）
  Map<String, dynamic>? _pendingChapter;
  Map<String, dynamic>? get pendingChapter => _pendingChapter;

  /// 是否有待访问章节（用于判断是否由 push 进入登录页，避免 app_shell replaceAll 覆盖）
  bool get hasPendingChapter => _pendingChapter != null;

  void setPendingChapter(Map<String, dynamic> chapter) {
    _pendingChapter = chapter;
    notifyListeners();
  }

  Map<String, dynamic>? consumePendingChapter() {
    final p = _pendingChapter;
    _pendingChapter = null;
    notifyListeners();
    return p;
  }

  /// 严格解析 is_vip：仅明确为 true 时才算 VIP
  static bool _parseIsVip(dynamic raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true' || raw == '1';
    if (raw is int) return raw == 1;
    return false;
  }

  /// 从 profiles 表加载 VIP 状态，登录成功后调用
  Future<void> loadVipStatus(String uid) async {
    try {
      final res = await supabase
          .from('profiles')
          .select('is_vip')
          .eq('id', uid)
          .maybeSingle();
      _isVip = _parseIsVip(res?['is_vip']);
      notifyListeners();
    } catch (e) {
      log('UserManager.loadVipStatus error: $e');
      _isVip = false;
      notifyListeners();
    }
  }

  /// 登出时清空
  void clear() {
    _isVip = null;
    _pendingChapter = null;
    _forceLogin = true; // 登出后强制先跳登录页
    notifyListeners();
  }
}
