import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/transactions_calendar_view.dart';
import '../widgets/transactions_weekly_view.dart';
import '../widgets/transactions_monthly_view.dart';
import '../widgets/transactions_total_view.dart';
import '../widgets/transactions_list_view.dart';
import '../../../settings/presentation/screens/transaction_filters_screen.dart';

enum TransactionsViewType {
  list,
  calendar,
  weekly,
  monthly,
  total,
}

final transactionsViewTypeProvider =
    StateProvider<TransactionsViewType>((ref) => TransactionsViewType.list);

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(transactionsViewTypeProvider.notifier).state =
            TransactionsViewType.values[_tabController.index];
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentView = ref.watch(transactionsViewTypeProvider);

    // Synchroniser le TabController avec le state
    if (_tabController.index != currentView.index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(currentView.index);
      });
    }

    final filters = ref.watch(transactionFiltersProvider);
    final hasActiveFilters = filters != null && filters.hasFilters;

    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactions),
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt),
              color: Colors.blue,
              tooltip: l10n.translate('active_filters'),
              onPressed: () {
                context.push('/transaction-filters');
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.translate('filtering_search'),
            onPressed: () {
              context.push('/transaction-filters');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            ref.read(transactionsViewTypeProvider.notifier).state =
                TransactionsViewType.values[index];
          },
          tabs: [
            Tab(
              icon: const Icon(Icons.list),
              text: l10n.translate('list'),
            ),
            Tab(
              icon: const Icon(Icons.calendar_today),
              text: l10n.calendar,
            ),
            Tab(
              icon: const Icon(Icons.view_week),
              text: l10n.translate('week'),
            ),
            Tab(
              icon: const Icon(Icons.calendar_month),
              text: l10n.translate('month'),
            ),
            Tab(
              icon: const Icon(Icons.summarize),
              text: l10n.translate('total'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TransactionsListView(),
          TransactionsCalendarView(),
          TransactionsWeeklyView(),
          TransactionsMonthlyView(),
          TransactionsTotalView(),
        ],
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add-transaction');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

