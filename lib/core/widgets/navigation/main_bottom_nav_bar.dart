import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (selectedIndex) {
        switch (selectedIndex) {
          case 0:
            context.go('/transactions');
            break;
          case 1:
            context.go('/stats');
            break;
          case 2:
            context.go('/accounts');
            break;
          case 3:
            context.go('/settings');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.accentSecondary,
      unselectedItemColor: AppColors.darkTextSecondary,
      backgroundColor: AppColors.darkCard,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Transactions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Comptes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          activeIcon: Icon(Icons.settings),
          label: 'Paramètres',
        ),
      ],
    );
  }
}

