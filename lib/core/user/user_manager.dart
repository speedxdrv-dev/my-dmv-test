import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../utils/resources/supabase.dart';

/// 全局用户状态管理，存储 VIP 等信息
class UserManager extends ChangeNotifier {
  UserManager._();

  static final UserManager _instance = UserManager._();

  factory UserManager() => _instance;

  bool? _isVip;

  bool? get isVip => _isVip;

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
    notifyListeners();
  }
}
