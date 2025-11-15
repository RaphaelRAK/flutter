import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'infrastructure/db/database_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerAsync = ref.watch(appRouterProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    return routerAsync.when(
      data: (router) => settingsAsync.when(
        data: (settings) {
          // Convertir la valeur string du thème en ThemeMode
          ThemeMode themeMode;
          switch (settings.theme) {
            case 'light':
              themeMode = ThemeMode.light;
              break;
            case 'dark':
              themeMode = ThemeMode.dark;
              break;
            case 'system':
              themeMode = ThemeMode.system;
              break;
            default:
              themeMode = ThemeMode.dark; // Par défaut
          }

          return MaterialApp.router(
            title: 'Flut Budget',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('fr', 'FR'),
            routerConfig: router,
          );
        },
        loading: () => MaterialApp.router(
          title: 'Flut Budget',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Par défaut pendant le chargement
          routerConfig: router,
        ),
        error: (error, stack) => MaterialApp.router(
          title: 'Flut Budget',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Par défaut en cas d'erreur
          routerConfig: router,
        ),
      ),
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Erreur: $error')),
        ),
      ),
    );
  }
}

