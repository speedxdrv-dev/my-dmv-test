// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter();

  @override
  final Map<String, PageFactory> pagesMap = {
    AuthRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AuthPage(),
      );
    },
    DemoHomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const DemoHomePage(),
      );
    },
    HandbookDetailRoute.name: (routeData) {
      final args = routeData.argsAs<HandbookDetailRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: HandbookDetailPage(
          key: args.key,
          title: args.title,
          content: args.content,
        ),
      );
    },
    HandbookListRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HandbookListPage(),
      );
    },
    HomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const Home(),
      );
    },
    HomePageRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomePage(),
      );
    },
    IntroRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const IntroPage(),
      );
    },
    ProfileRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ProfilePage(),
      );
    },
    QuizEndRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const QuizEndPage(),
      );
    },
    QuizRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const QuizPage(),
      );
    },
    ReleaseRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ReleasePage(),
      );
    },
    SkeletonRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const Skeleton(),
      );
    },
    SupabaseQuizRoute.name: (routeData) {
      final args = routeData.argsAs<SupabaseQuizRouteArgs>(
          orElse: () => const SupabaseQuizRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: SupabaseQuizPage(
          key: args.key,
          categories: args.categories,
          mistakeIds: args.mistakeIds,
          title: args.title,
          onBack: args.onBack,
          onMistakesEmpty: args.onMistakesEmpty,
          isTraditional: args.isTraditional,
        ),
      );
    },
    SupabaseUnavailableRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SupabaseUnavailablePage(),
      );
    },
  };
}

/// generated route for
/// [AuthPage]
class AuthRoute extends PageRouteInfo<void> {
  const AuthRoute({List<PageRouteInfo>? children})
      : super(
          AuthRoute.name,
          initialChildren: children,
        );

  static const String name = 'AuthRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [DemoHomePage]
class DemoHomeRoute extends PageRouteInfo<void> {
  const DemoHomeRoute({List<PageRouteInfo>? children})
      : super(
          DemoHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'DemoHomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HandbookDetailPage]
class HandbookDetailRoute extends PageRouteInfo<HandbookDetailRouteArgs> {
  HandbookDetailRoute({
    Key? key,
    required String title,
    required String content,
    List<PageRouteInfo>? children,
  }) : super(
          HandbookDetailRoute.name,
          args: HandbookDetailRouteArgs(
            key: key,
            title: title,
            content: content,
          ),
          initialChildren: children,
        );

  static const String name = 'HandbookDetailRoute';

  static const PageInfo<HandbookDetailRouteArgs> page =
      PageInfo<HandbookDetailRouteArgs>(name);
}

class HandbookDetailRouteArgs {
  const HandbookDetailRouteArgs({
    this.key,
    required this.title,
    required this.content,
  });

  final Key? key;

  final String title;

  final String content;

  @override
  String toString() {
    return 'HandbookDetailRouteArgs{key: $key, title: $title, content: $content}';
  }
}

/// generated route for
/// [HandbookListPage]
class HandbookListRoute extends PageRouteInfo<void> {
  const HandbookListRoute({List<PageRouteInfo>? children})
      : super(
          HandbookListRoute.name,
          initialChildren: children,
        );

  static const String name = 'HandbookListRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [Home]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HomePage]
class HomePageRoute extends PageRouteInfo<void> {
  const HomePageRoute({List<PageRouteInfo>? children})
      : super(
          HomePageRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomePageRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [IntroPage]
class IntroRoute extends PageRouteInfo<void> {
  const IntroRoute({List<PageRouteInfo>? children})
      : super(
          IntroRoute.name,
          initialChildren: children,
        );

  static const String name = 'IntroRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
      : super(
          ProfileRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProfileRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [QuizEndPage]
class QuizEndRoute extends PageRouteInfo<void> {
  const QuizEndRoute({List<PageRouteInfo>? children})
      : super(
          QuizEndRoute.name,
          initialChildren: children,
        );

  static const String name = 'QuizEndRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [QuizPage]
class QuizRoute extends PageRouteInfo<void> {
  const QuizRoute({List<PageRouteInfo>? children})
      : super(
          QuizRoute.name,
          initialChildren: children,
        );

  static const String name = 'QuizRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ReleasePage]
class ReleaseRoute extends PageRouteInfo<void> {
  const ReleaseRoute({List<PageRouteInfo>? children})
      : super(
          ReleaseRoute.name,
          initialChildren: children,
        );

  static const String name = 'ReleaseRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [Skeleton]
class SkeletonRoute extends PageRouteInfo<void> {
  const SkeletonRoute({List<PageRouteInfo>? children})
      : super(
          SkeletonRoute.name,
          initialChildren: children,
        );

  static const String name = 'SkeletonRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SupabaseQuizPage]
class SupabaseQuizRoute extends PageRouteInfo<SupabaseQuizRouteArgs> {
  SupabaseQuizRoute({
    Key? key,
    List<String>? categories,
    List<String>? mistakeIds,
    String? title,
    void Function()? onBack,
    void Function()? onMistakesEmpty,
    bool isTraditional = false,
    List<PageRouteInfo>? children,
  }) : super(
          SupabaseQuizRoute.name,
          args: SupabaseQuizRouteArgs(
            key: key,
            categories: categories,
            mistakeIds: mistakeIds,
            title: title,
            onBack: onBack,
            onMistakesEmpty: onMistakesEmpty,
            isTraditional: isTraditional,
          ),
          initialChildren: children,
        );

  static const String name = 'SupabaseQuizRoute';

  static const PageInfo<SupabaseQuizRouteArgs> page =
      PageInfo<SupabaseQuizRouteArgs>(name);
}

class SupabaseQuizRouteArgs {
  const SupabaseQuizRouteArgs({
    this.key,
    this.categories,
    this.mistakeIds,
    this.title,
    this.onBack,
    this.onMistakesEmpty,
    this.isTraditional = false,
  });

  final Key? key;

  final List<String>? categories;

  final List<String>? mistakeIds;

  final String? title;

  final void Function()? onBack;

  final void Function()? onMistakesEmpty;

  final bool isTraditional;

  @override
  String toString() {
    return 'SupabaseQuizRouteArgs{key: $key, categories: $categories, mistakeIds: $mistakeIds, title: $title, onBack: $onBack, onMistakesEmpty: $onMistakesEmpty, isTraditional: $isTraditional}';
  }
}

/// generated route for
/// [SupabaseUnavailablePage]
class SupabaseUnavailableRoute extends PageRouteInfo<void> {
  const SupabaseUnavailableRoute({List<PageRouteInfo>? children})
      : super(
          SupabaseUnavailableRoute.name,
          initialChildren: children,
        );

  static const String name = 'SupabaseUnavailableRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
