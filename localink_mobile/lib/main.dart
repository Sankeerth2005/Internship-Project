import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/verify_otp_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/auth_state.dart';
import 'features/business/data/models/business_models.dart';
import 'features/business/presentation/screens/home_screen.dart';
import 'features/business/presentation/screens/favorites_screen.dart';
import 'features/business/presentation/screens/business_dashboard_screen.dart';
import 'features/business/presentation/screens/business_registration_screen.dart';
import 'features/business/presentation/screens/business_detail_screen.dart';
import 'features/business/presentation/screens/ai_assistant_screen.dart';
import 'features/business/presentation/screens/for_you_feed_screen.dart';
import 'features/business/presentation/screens/analytics_dashboard_screen.dart';
import 'features/admin/presentation/screens/admin_heatmap_screen.dart';
import 'features/shared/presentation/screens/main_shell.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';

import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';

void main() {
  runApp(const ProviderScope(child: LocalinkApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/reset-password';

      if (authState is AuthUnauthenticated && !isLoggingIn) {
        return '/login';
      }

      if (authState is AuthAuthenticated && isLoggingIn) {
        // Normalize matching on backend role string (lowercase/uppercase check)
        final role = authState.userType.toLowerCase().trim();
        if (role == 'admin') {
          return '/admin-dashboard';
        }
        if (role == 'businessowner') {
          return '/business-dashboard';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = state.extra as String;
          return VerifyOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return ResetPasswordScreen(
            email: extra['email']!,
            otp: extra['otp']!,
          );
        },
      ),

      // User dashboard shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Business owner dashboard (no bottom nav — separate screen)
      GoRoute(
        path: '/business-dashboard',
        builder: (context, state) => const BusinessDashboardScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/register-business',
        builder: (context, state) {
          final business = state.extra as BusinessDto?;
          return BusinessRegistrationScreen(businessToEdit: business);
        },
      ),
      GoRoute(
        path: '/owner-profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/business-detail/:id',
        builder: (context, state) => BusinessDetailScreen(
          businessId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/for-you',
        builder: (context, state) => const ForYouFeedScreen(),
      ),
      GoRoute(
        path: '/owner-analytics/:id/:name',
        builder: (context, state) => AnalyticsDashboardScreen(
          businessId: int.parse(state.pathParameters['id']!),
          businessName: state.pathParameters['name']!,
        ),
      ),
      GoRoute(
        path: '/admin-heatmap',
        builder: (context, state) => const AdminHeatmapScreen(),
      ),
    ],
  );
});

class GoRouterRefreshListenable extends ChangeNotifier {
  GoRouterRefreshListenable(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class LocalinkApp extends ConsumerWidget {
  const LocalinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize rate limit feedback callback
    DioClient.onRateLimited = () {
      scaffoldMessengerKey.currentState?.clearSnackBars();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Too many requests. Please wait a moment before trying again.'),
          backgroundColor: Color(0xFFFF4D4F),
        ),
      );
    };

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Vocal for Sanatan',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
