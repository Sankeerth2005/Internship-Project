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
import 'features/shared/presentation/screens/support_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';

import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';

void main() {
  runApp(const ProviderScope(child: LocalinkApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshListenable(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.watch(authProvider); // Listen to auth state changes
      final splashShown = ref.watch(splashShownProvider);
      final currentLocation = state.matchedLocation;

      // If splash has not completed displaying yet, force staying on /splash
      if (!splashShown) {
        if (currentLocation == '/splash') {
          return null;
        }
        return '/splash';
      }

      // If splash has completed but location is still /splash, redirect away from splash
      if (currentLocation == '/splash') {
        if (authState is AuthAuthenticated) {
          final role = authState.userType.toLowerCase().trim();
          if (role == 'admin') return '/admin-dashboard';
          if (role == 'businessowner' || role == 'client') return '/business-dashboard';
          return '/home';
        }
        return '/welcome';
      }

      // If the app is still in the initial authentication check,
      // allow it to stay on current public screen.
      if (authState is AuthInitial) {
        return null; 
      }

      // Define public routes that an unauthenticated user can access.
      // These are routes that don't require authentication.
      final isPublicRoute = currentLocation == '/welcome' ||
          currentLocation == '/login' ||
          currentLocation == '/signup' ||
          currentLocation == '/forgot-password' ||
          currentLocation == '/verify-otp' ||
          currentLocation == '/reset-password';

      // If the user is NOT authenticated and trying to access a protected route,
      // redirect them to the welcome screen.
      if (authState is AuthUnauthenticated && !isPublicRoute) {
        return '/welcome';
      }

      // If the user IS authenticated...
      if (authState is AuthAuthenticated) {
        // ...and they are trying to access any public route,
        // redirect them to their appropriate dashboard.
        if (isPublicRoute) {
          final role = authState.userType.toLowerCase().trim();
          if (role == 'admin') {
            return '/admin-dashboard';
          }
          if (role == 'businessowner' || role == 'client') {
            return '/business-dashboard';
          }
          return '/home';
        }
      }

      return null; // No redirection needed, continue to the requested route.
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final role = state.extra as String?;
          return LoginScreen(selectedRole: role);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final role = state.extra as String?;
          return SignupScreen(preSelectedRole: role);
        },
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
                path: '/support',
                builder: (context, state) => const SupportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai-assistant',
                builder: (context, state) => const AiAssistantScreen(),
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
        parentNavigatorKey: _rootNavigatorKey,
        path: '/edit-business/:id',
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
        path: '/profile',
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
        parentNavigatorKey: _rootNavigatorKey,
        path: '/analytics/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final business = state.extra as BusinessDto?;
          return AnalyticsDashboardScreen(
            businessId: id,
            businessName: business?.businessName ?? 'Business Performance',
          );
        },
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
    ref.listen<bool>(
      splashShownProvider,
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
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
