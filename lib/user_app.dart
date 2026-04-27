// User-only app widget — uses userRouterProvider (no admin routes).
// Paired with lib/main_user.dart for the Play Store build.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/language_provider.dart';
import 'routes/user_router.dart';
import 'features/profile/providers/profile_provider.dart';

class UserSanadApp extends ConsumerWidget {
  const UserSanadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final router = ref.watch(userRouterProvider);
    final profileState = ref.watch(profileProvider);
    final bool isDarkMode = profileState.user?.settings.darkMode ?? false;

    return MaterialApp.router(
      title: 'Sanad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      locale: languageState.locale,
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
