import 'package:go_router/go_router.dart';
import '../features/invoice/presentation/splash_screen.dart';
import '../features/invoice/presentation/main_navigation_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) {
        final tabParam = state.uri.queryParameters['tab'];
        final initialTab = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
        return MainNavigationScreen(initialTabIndex: initialTab);
      },
    ),
  ],
);

