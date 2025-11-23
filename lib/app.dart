import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'infrastructure/db/database_provider.dart';
import 'core/widgets/navigation/lock_wrapper.dart';
import 'core/localization/app_localizations.dart';

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

          // Déterminer la locale depuis les settings
          final languageCode = settings.language;
          final requestedLocale = _getLocaleFromCode(languageCode);
          
          // Pour Material/Cupertino, utiliser fr_FR si c'est mg_MG (non supporté)
          final materialLocale = requestedLocale.languageCode == 'mg' 
              ? const Locale('fr', 'FR') 
              : requestedLocale;

          return LockWrapper(
            child: MaterialApp.router(
              title: 'Flut Budget',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: [
                // Utiliser un delegate personnalisé qui force la locale demandée pour AppLocalizations
                _AppLocalizationsDelegateWithLocale(requestedLocale),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('fr', 'FR'),
                Locale('en', 'US'),
                Locale('es', 'ES'),
                Locale('zh', 'CN'),
                Locale('mg', 'MG'),
              ],
              locale: materialLocale, // Utiliser la locale Material (fr_FR pour mg_MG)
              localeResolutionCallback: (locale, supportedLocales) {
                // Pour Material/Cupertino, utiliser fr_FR si c'est mg_MG
                if (locale != null && locale.languageCode == 'mg') {
                  return const Locale('fr', 'FR');
                }
                // Pour les autres locales, retourner la locale telle quelle
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale?.languageCode) {
                    return supportedLocale;
                  }
                }
                return supportedLocales.first;
              },
              routerConfig: router,
            ),
          );
        },
        loading: () => LockWrapper(
          child: MaterialApp.router(
            title: 'Flut Budget',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, // Par défaut pendant le chargement
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
              Locale('es', 'ES'),
              Locale('zh', 'CN'),
              Locale('mg', 'MG'),
            ],
            locale: const Locale('fr', 'FR'), // Par défaut pendant le chargement
            localeResolutionCallback: _localeResolutionCallback,
            routerConfig: router,
          ),
        ),
        error: (error, stack) => LockWrapper(
          child: MaterialApp.router(
            title: 'Flut Budget',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, // Par défaut en cas d'erreur
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
              Locale('es', 'ES'),
              Locale('zh', 'CN'),
              Locale('mg', 'MG'),
            ],
            locale: const Locale('fr', 'FR'), // Par défaut en cas d'erreur
            localeResolutionCallback: _localeResolutionCallback,
            routerConfig: router,
          ),
        ),
      ),
      loading: () => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
          Locale('es', 'ES'),
          Locale('zh', 'CN'),
          Locale('mg', 'MG'),
        ],
        locale: const Locale('fr', 'FR'),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
          Locale('es', 'ES'),
          Locale('zh', 'CN'),
          Locale('mg', 'MG'),
        ],
        locale: const Locale('fr', 'FR'),
        home: Scaffold(
          body: Center(child: Text('Erreur: $error')),
        ),
      ),
    );
  }

  static Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en', 'US');
      case 'es':
        return const Locale('es', 'ES');
      case 'zh':
        return const Locale('zh', 'CN');
      case 'mg':
        return const Locale('mg', 'MG');
      case 'fr':
      default:
        return const Locale('fr', 'FR');
    }
  }

  static Locale? _localeResolutionCallback(Locale? locale, Iterable<Locale> supportedLocales) {
    // Pour Material/Cupertino, utiliser fr_FR si c'est mg_MG
    if (locale != null && locale.languageCode == 'mg') {
      return const Locale('fr', 'FR');
    }
    // Pour les autres locales, retourner la locale telle quelle
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale?.languageCode) {
        return supportedLocale;
      }
    }
    return supportedLocales.first;
  }
}

// Delegate personnalisé qui force une locale spécifique pour AppLocalizations
class _AppLocalizationsDelegateWithLocale extends LocalizationsDelegate<AppLocalizations> {
  final Locale forcedLocale;
  
  const _AppLocalizationsDelegateWithLocale(this.forcedLocale);

  @override
  bool isSupported(Locale locale) => true; // Toujours supporter pour forcer la locale

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Ignorer la locale passée et utiliser la locale forcée
    return AppLocalizations(forcedLocale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegateWithLocale old) => 
      old.forcedLocale != forcedLocale;
}

