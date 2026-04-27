import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/language_provider.dart';
import 'routes/app_router.dart';
import 'features/profile/providers/profile_provider.dart';

class SanadApp extends ConsumerWidget {
  const SanadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final router = ref.watch(routerProvider);

    // Watch profile state to get dark mode setting
    final profileState = ref.watch(profileProvider);
    final bool? userPref = profileState.user?.settings.darkMode;

    // Use user preference if set, otherwise follow system
    final ThemeMode themeMode;
    if (userPref != null) {
      themeMode = userPref ? ThemeMode.dark : ThemeMode.light;
    } else {
      themeMode = ThemeMode.system;
    }

    return MaterialApp.router(
      title: 'Sanad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
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
    );
  }
}
