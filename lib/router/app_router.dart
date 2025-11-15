import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/transactions/presentation/screens/transactions_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/features/presentation/screens/features_screen.dart';
import '../features/stats/presentation/screens/stats_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/daily/presentation/screens/daily_screen.dart';
import '../features/screenshots/presentation/screens/screenshots_screen.dart';
import '../features/help/presentation/screens/help_center_screen.dart';
import '../core/utils/preferences_helper.dart';

final appRouterProvider = FutureProvider<GoRouter>((ref) async {
  final isFirstLaunch = await PreferencesHelper.isFirstLaunch();
  
  return GoRouter(
    initialLocation: isFirstLaunch ? '/onboarding' : '/home',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => const TransactionsListScreen(),
      ),
      GoRoute(
        path: '/add-transaction',
        name: 'add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/features',
        name: 'features',
        builder: (context, state) => const FeaturesScreen(),
      ),
      GoRoute(
        path: '/stats',
        name: 'stats',
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: '/accounts',
        name: 'accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/daily',
        name: 'daily',
        builder: (context, state) => const DailyScreen(),
      ),
      GoRoute(
        path: '/screenshots',
        name: 'screenshots',
        builder: (context, state) => const ScreenshotsScreen(),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
    ],
  );
});

