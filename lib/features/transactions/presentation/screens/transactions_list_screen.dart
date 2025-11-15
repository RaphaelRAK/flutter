import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../widgets/transactions_calendar_view.dart';
import '../widgets/transactions_weekly_view.dart';
import '../widgets/transactions_monthly_view.dart';
import '../widgets/transactions_total_view.dart';

enum TransactionsViewType {
  calendar,
  weekly,
  monthly,
  total,
}

final transactionsViewTypeProvider =
    StateProvider<TransactionsViewType>((ref) => TransactionsViewType.calendar);

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
    _tabController = TabController(length: 4, vsync: this);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implémenter la recherche
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

