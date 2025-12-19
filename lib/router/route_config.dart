import 'package:go_router/go_router.dart';
import '../core/constants/route_names.dart';
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
import '../features/transactions/presentation/screens/recurring_transactions_screen.dart';
import '../features/transactions/presentation/screens/add_recurring_transaction_screen.dart';
import '../features/settings/presentation/screens/reminders_screen.dart';
import '../features/settings/presentation/screens/add_reminder_screen.dart';
import '../features/settings/presentation/screens/transaction_filters_screen.dart';
import '../features/settings/presentation/screens/lock_screen.dart';
import '../features/settings/presentation/screens/lock_setup_screen.dart';
import '../features/settings/presentation/screens/premium_screen.dart';
import '../infrastructure/db/drift_database.dart';

/// Configuration des routes de l'application
class RouteConfig {
  static List<RouteBase> getRoutes() {
    return [
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionsListScreen(),
      ),
      GoRoute(
        path: RouteNames.addTransaction,
        name: 'add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: RouteNames.editTransaction,
        name: 'edit-transaction',
        builder: (context, state) {
          final transaction = state.extra as Transaction?;
          return AddTransactionScreen(transactionToEdit: transaction);
        },
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.premium,
        name: 'premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: RouteNames.features,
        name: 'features',
        builder: (context, state) => const FeaturesScreen(),
      ),
      GoRoute(
        path: RouteNames.stats,
        name: 'stats',
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: RouteNames.accounts,
        name: 'accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: RouteNames.calendar,
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: RouteNames.daily,
        name: 'daily',
        builder: (context, state) => const DailyScreen(),
      ),
      GoRoute(
        path: RouteNames.screenshots,
        name: 'screenshots',
        builder: (context, state) => const ScreenshotsScreen(),
      ),
      GoRoute(
        path: RouteNames.help,
        name: 'help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: RouteNames.recurringTransactions,
        name: 'recurring-transactions',
        builder: (context, state) => const RecurringTransactionsScreen(),
      ),
      GoRoute(
        path: RouteNames.addRecurringTransaction,
        name: 'add-recurring-transaction',
        builder: (context, state) {
          final rule = state.extra as RecurringRule?;
          return AddRecurringTransactionScreen(ruleToEdit: rule);
        },
      ),
      GoRoute(
        path: RouteNames.reminders,
        name: 'reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: RouteNames.addReminder,
        name: 'add-reminder',
        builder: (context, state) {
          final reminder = state.extra as Reminder?;
          return AddReminderScreen(reminderToEdit: reminder);
        },
      ),
      GoRoute(
        path: RouteNames.transactionFilters,
        name: 'transaction-filters',
        builder: (context, state) => const TransactionFiltersScreen(),
      ),
      GoRoute(
        path: RouteNames.lock,
        name: 'lock',
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: RouteNames.lockSetup,
        name: 'lock-setup',
        builder: (context, state) => const LockSetupScreen(),
      ),
    ];
  }
}

