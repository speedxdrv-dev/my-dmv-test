import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/router/app_router.dart';
import '../config/supabase/supabase_config.dart';
import '../user/user_manager.dart';
import '../utils/resources/supabase.dart';

/// 应用根壳：处理认证状态并决定初始跳转
@RoutePage(
  name: "HomeRoute",
)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isReachable) {
      var hasNavigated = false;
      supabase.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.initialSession) {
          hasNavigated = true;
          _navigateToIntro();
        } else if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.signedOut ||
            data.event == AuthChangeEvent.userDeleted) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _navigateBasedOnAuth(data.event);
          });
        }
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !hasNavigated) _navigateToIntro();
      });
    } else {
      _navigateToIntro();
    }
  }

  void _navigateToIntro() {
    if (!mounted) return;
    if (!SupabaseConfig.isReachable) SupabaseConfig.isReachable = true;
    appRouter.replaceAll([const HomeRoute(), const IntroRoute()]);
  }

  void _navigateBasedOnAuth(AuthChangeEvent event) async {
    if (!mounted) return;
    if (!SupabaseConfig.isReachable) SupabaseConfig.isReachable = true;
    if (event == AuthChangeEvent.signedIn) {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await context.read<UserManager>().loadVipStatus(user.id);
      }
      if (!mounted) return;
      appRouter.replaceAll([const HomeRoute(), const HomePageRoute()]);
    } else {
      // 退出登录后进入介绍页，用户点击「开始我的通关之旅」进入答题目录
      // 只有点击第四章及以后才跳转登录页
      context.read<UserManager>().clear();
      appRouter.replaceAll([const HomeRoute(), const IntroRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}
