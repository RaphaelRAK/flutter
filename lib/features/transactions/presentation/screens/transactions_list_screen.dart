import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt),
              color: Colors.blue,
              tooltip: 'Filtres actifs',
              onPressed: () {
                context.push('/transaction-filters');
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrage et recherche',
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
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'Liste',
            ),
            Tab(
              icon: Icon(Icons.calendar_today),
              text: 'Calendrier',
            ),
            Tab(
              icon: Icon(Icons.view_week),
              text: 'Semaine',
            ),
            Tab(
              icon: Icon(Icons.calendar_month),
              text: 'Mois',
            ),
            Tab(
              icon: Icon(Icons.summarize),
              text: 'Total',
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

