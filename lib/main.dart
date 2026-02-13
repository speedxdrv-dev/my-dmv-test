//force update 123
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/router/app_router.dart';
import 'core/config/supabase/setup.dart';
import 'core/preferences/intro_preference.dart';
import 'core/config/supabase/supabase_config.dart';
import 'core/config/themes/app_theme.dart';
import 'core/user/user_manager.dart';
import 'core/utils/resources/supabase.dart';
import 'features/about/data/app_package_info.dart';
import 'features/quiz/presentation/provider/quiz_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 捕获错误并在控制台显示，便于排查白屏
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: $details');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher Error: $error\n$stack');
    return true;
  };

  try {
    usePathUrlStrategy();
    await setupSupabase();
    if (kIsWeb) {
      try {
        if (Uri.base.queryParameters['reset'] == '1') {
          await IntroPreference.saveIntroSeen(false);
          await supabase.auth.signOut();
        }
      } catch (_) {}
    }
    await AppPackageInfo().init();
    // 预加载繁体中文字体，避免「個」等字符显示为方框
    GoogleFonts.notoSansTc();
    await GoogleFonts.pendingFonts();
    runApp(const MyApp());
  } catch (e, s) {
    debugPrint('>>> main() 启动错误: $e');
    debugPrint('>>> 堆栈: $s');
    runApp(_ErrorApp(error: e, stack: s));
  }
}

/// 启动失败时显示的错误页，便于在浏览器中看到具体错误
class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.error, required this.stack});

  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('启动失败', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SelectableText('$error', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                SelectableText('$stack', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserManager(),
        ),
        ChangeNotifierProvider(
          create: (context) => QuizProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Zyland驾考通',
        theme: AppTheme.lightTheme,
        // darkTheme: AppTheme.darkTheme,
        routerConfig: appRouter.config(),
      ),
    );
  }
}

@RoutePage(
  name: "HomeRoute",
)
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isReachable) {
      var hasNavigated = false;
      supabase.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.initialSession) {
          hasNavigated = true;
          _navigateBasedOnAuth();
        } else if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.signedOut ||
            data.event == AuthChangeEvent.userDeleted) {
          Future.delayed(const Duration(milliseconds: 100), _navigateBasedOnAuth);
        }
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !hasNavigated) _navigateBasedOnAuth();
      });
    } else {
      _navigateBasedOnAuth();
    }
  }

  void _navigateBasedOnAuth() async {
    if (!SupabaseConfig.isReachable) {
      SupabaseConfig.isReachable = true;
    }
    if (!mounted) return;
    final introSeen = await IntroPreference.loadIntroSeen();
    if (!mounted) return;
    if (!introSeen) {
      appRouter.replaceAll([const HomeRoute(), const IntroRoute()]);
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) {
      Provider.of<UserManager>(context, listen: false).clear();
      appRouter.replaceAll([const HomeRoute(), const AuthRoute()]);
    } else {
      await Provider.of<UserManager>(context, listen: false)
          .loadVipStatus(user.id);
      if (!mounted) return;
      appRouter.replaceAll([const HomeRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}
