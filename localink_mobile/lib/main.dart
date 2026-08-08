import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/verify_otp_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/change_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/shared/presentation/screens/privacy_policy_screen.dart';
import 'features/shared/presentation/screens/account_deletion_screen.dart';
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
import 'features/chat/presentation/screens/conversations_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/catalog/presentation/screens/manage_catalog_screen.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/role_routes.dart';
import 'core/network/dio_client.dart';
import 'core/monitoring/crash_reporter.dart';
import 'features/shared/presentation/widgets/offline_banner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = CrashReporter.recordFlutterError;

  runZonedGuarded(
    () {
      // Never throw before runApp — that freezes the Android native splash
      // (black screen + centered launcher icon) with no recoverable UI.
      String? releaseConfigError;
      try {
        AppConfig.assertReleaseReady();
      } on StateError catch (e) {
        releaseConfigError = e.message;
        debugPrint('Release config error: $e');
      }

      runApp(
        ProviderScope(
          child: releaseConfigError == null
              ? const LocalinkApp()
              : _MisconfiguredReleaseApp(message: releaseConfigError),
        ),
      );
    },
    (error, stack) {
      CrashReporter.recordZoneError(error, stack);
    },
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

String _homeForRole(String userType) => RoleRoutes.homeForRole(userType);

bool _isAdminRoute(String location) =>
    location == '/admin-dashboard' || location == '/admin-heatmap';

bool _isOwnerRoute(String location) =>
    location == '/business-dashboard' ||
    location.startsWith('/register-business') ||
    location.startsWith('/edit-business') ||
    location.startsWith('/analytics/') ||
    location.startsWith('/owner-analytics/') ||
    location.startsWith('/manage-catalog/') ||
    location == '/owner-profile';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshListenable(ref),
    errorBuilder: (context, state) =>
        _RouteErrorScreen(error: state.error?.toString()),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final splashShown = ref.read(splashShownProvider);
      final currentLocation = state.matchedLocation;

      if (!splashShown) {
        if (currentLocation == '/splash') return null;
        return '/splash';
      }

      if (currentLocation == '/splash') {
        if (authState is AuthAuthenticated) {
          return _homeForRole(authState.userType);
        }
        return '/welcome';
      }

      if (authState is AuthInitial) {
        return null;
      }

      final isPublicRoute = currentLocation == '/welcome' ||
          currentLocation == '/login' ||
          currentLocation == '/signup' ||
          currentLocation == '/forgot-password' ||
          currentLocation == '/verify-otp' ||
          currentLocation == '/reset-password' ||
          currentLocation == '/privacy-policy';

      if (authState is AuthUnauthenticated && !isPublicRoute) {
        return '/welcome';
      }

      if (authState is AuthAuthenticated) {
        if (isPublicRoute && currentLocation != '/privacy-policy') {
          return _homeForRole(authState.userType);
        }

        final role = authState.userType;
        if (_isAdminRoute(currentLocation) && !RoleRoutes.isAdmin(role)) {
          return _homeForRole(role);
        }
        if (_isOwnerRoute(currentLocation) &&
            !RoleRoutes.canAccessOwnerRoutes(role)) {
          return _homeForRole(role);
        }
      }

      return null;
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
          final email = state.extra is String
              ? state.extra as String
              : (state.uri.queryParameters['email'] ?? '');
          if (email.trim().isEmpty) {
            return const ForgotPasswordScreen();
          }
          return VerifyOtpScreen(email: email.trim());
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          String email = '';
          String otp = '';
          final extra = state.extra;
          if (extra is Map) {
            email = (extra['email'] ?? '').toString();
            otp = (extra['otp'] ?? '').toString();
          }
          email = email.isNotEmpty
              ? email
              : (state.uri.queryParameters['email'] ?? '');
          otp = otp.isNotEmpty
              ? otp
              : (state.uri.queryParameters['otp'] ?? '');
          if (email.trim().isEmpty || otp.trim().isEmpty) {
            return const ForgotPasswordScreen();
          }
          return ResetPasswordScreen(
            email: email.trim(),
            otp: otp.trim(),
          );
        },
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

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

      GoRoute(
        path: '/business-dashboard',
        builder: (context, state) => const BusinessDashboardScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/conversations',
        builder: (context, state) {
          final isOwner = state.uri.queryParameters['isOwner'] == 'true';
          return ConversationsScreen(isOwner: isOwner);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final role = state.uri.queryParameters['role'] ?? 'User';
          final title = state.uri.queryParameters['title'] ?? 'Chat';
          return ChatScreen(conversationId: id, role: role, title: title);
        },
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
      GoRoute(
        path: '/manage-catalog/:id',
        builder: (context, state) => ManageCatalogScreen(
          businessId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/delete-account',
        builder: (context, state) => const AccountDeletionScreen(),
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

    DioClient.onRateLimited = () {
      scaffoldMessengerKey.currentState?.clearSnackBars();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Too many requests. Please wait a moment before trying again.',
          ),
          backgroundColor: Color(0xFFFF4D4F),
        ),
      );
    };

    return MaterialApp.router(
      title: 'Vocal For Sanatan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
      builder: (context, child) {
        return Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  final String? error;
  const _RouteErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF4D4F)),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (kDebugMode && error != null) ...[
                const SizedBox(height: 8),
                Text(error!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/welcome'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when a release APK was built without required --dart-define flags.
class _MisconfiguredReleaseApp extends StatelessWidget {
  final String message;
  const _MisconfiguredReleaseApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_suggest_outlined,
                    size: 56, color: Color(0xFFFF6600)),
                const SizedBox(height: 20),
                const Text(
                  'App build is misconfigured',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1918),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF5C5854),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Rebuild with scripts/build_manager_apk.ps1 and pass API_HOST '
                  '(and API_USE_HTTPS=true for production).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF9F9B96),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
