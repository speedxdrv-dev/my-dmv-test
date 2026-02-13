import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_shell.dart';
import '../../../features/about/presentation/pages/release_page.dart';
import '../../../features/admin/presentation/pages/admin_review_page.dart';
import '../../../features/auth/presentation/pages/auth_page.dart';
import '../../../features/demo/presentation/pages/demo_home_page.dart';
import '../../../features/handbook/presentation/pages/handbook_detail_page.dart';
import '../../../features/handbook/presentation/pages/handbook_list_page.dart';
import '../../../features/demo/presentation/pages/supabase_unavailable_page.dart';
import '../../../features/home/home_page.dart';
import '../../../features/intro/presentation/pages/intro_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';
import '../../../features/quiz/presentation/pages/quiz_end_page.dart';
import '../../../features/quiz/presentation/pages/quiz_page.dart';
import '../../../features/skeleton/skeleton.dart';
import '../../../features/supabase_quiz/presentation/pages/supabase_quiz_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: HomeRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(
              path: 'intro',
              page: IntroRoute.page,
            ),
            AutoRoute(
              path: 'auth',
              page: AuthRoute.page,
              keepHistory: false,
            ),
            AutoRoute(
              path: 'unavailable',
              page: SupabaseUnavailableRoute.page,
            ),
            AutoRoute(
              path: 'demo',
              page: DemoHomeRoute.page,
            ),
            AutoRoute(
              path: 'home',
              page: HomePageRoute.page,
            ),
            AutoRoute(
              path: 'supabase-quiz',
              page: SupabaseQuizRoute.page,
              fullscreenDialog: true,
            ),
            AutoRoute(
              path: '',
              page: SkeletonRoute.page,
              children: [
                AutoRoute(
                  path: 'profile',
                  page: ProfileRoute.page,
                  type: const RouteType.custom(),
                ),
              ],
            ),
            AutoRoute(
              path: 'quiz',
              page: QuizRoute.page,
            ),
            AutoRoute(
              path: 'finished',
              page: QuizEndRoute.page,
            ),
            AutoRoute(
              path: 'release',
              fullscreenDialog: true,
              page: ReleaseRoute.page,
            ),
            AutoRoute(
              path: 'handbook',
              page: HandbookListRoute.page,
            ),
            AutoRoute(
              path: 'handbook/detail',
              fullscreenDialog: true,
              page: HandbookDetailRoute.page,
            ),
            AutoRoute(
              path: 'admin-review',
              page: AdminReviewRoute.page,
            ),
          ],
        ),
      ];
}

final appRouter = AppRouter();
