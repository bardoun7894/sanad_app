import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/language_provider.dart';
import 'routes/app_router.dart';
import 'features/auth/providers/auth_provider.dart';

class SanadApp extends ConsumerWidget {
  const SanadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);

    // Watch auth state for route redirects
    final authState = ref.watch(authProvider);

    // Redirect based on auth status
    _handleAuthRouting(ref, authState);

    return MaterialApp.router(
      title: 'Sanad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      // Dynamic locale based on language provider
      locale: languageState.locale,
      supportedLocales: const [
        Locale('ar', 'SA'), // Arabic (Saudi Arabia)
        Locale('en', 'US'), // English (US)
        Locale('fr', 'FR'), // French (France)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Force rebuild when locale changes
      builder: (context, child) {
        return Directionality(
          textDirection: languageState.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }

  /// Handle navigation based on auth state
  void _handleAuthRouting(WidgetRef ref, AuthState authState) {
    // Post-frame callback to allow router to be available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final router = appRouter;
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
        final isAuthRoute = currentLocation.startsWith('/auth');

        // Redirect unauthenticated users to login
        if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
          if (currentLocation != AppRoutes.login) {
            appRouter.go(AppRoutes.login);
          }
        }

        // Redirect authenticated users with incomplete profile
        if (authState.status == AuthStatus.profileIncomplete &&
            currentLocation != AppRoutes.profileCompletion) {
          appRouter.go(AppRoutes.profileCompletion);
        }

        // Redirect authenticated users away from auth screens
        if (authState.status == AuthStatus.authenticated && isAuthRoute) {
          appRouter.go(AppRoutes.home);
        }
      } catch (e) {
        // Silently handle during initial navigation setup
        print('Auth routing error: $e');
      }
    });
  }
}
