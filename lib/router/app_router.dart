import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/transactions/presentation/screens/transactions_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transactions/presentation/screens/add_transaction_screen.dart';
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
    ],
  );
});

