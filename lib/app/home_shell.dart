import 'package:flutter/material.dart';
import 'package:alpha/features/board/presentation/weekly_view_screen.dart';
import 'package:alpha/features/board/presentation/monthly_view_screen.dart';
import 'package:alpha/features/board/presentation/quarterly_view_screen.dart';
import 'package:alpha/features/board/presentation/yearly_view_screen.dart';

/// Root shell with bottom navigation for weekly, monthly,
/// quarterly, and yearly views.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const WeeklyViewScreen();
      case 1:
        return const MonthlyViewScreen();
      case 2:
        return const QuarterlyViewScreen();
      case 3:
        return const YearlyViewScreen();
      default:
        return const WeeklyViewScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildBody()),
        NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.view_week_outlined),
              selectedIcon: Icon(Icons.view_week),
              label: 'Weekly',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Monthly',
            ),
            NavigationDestination(
              icon: Icon(Icons.date_range_outlined),
              selectedIcon: Icon(Icons.date_range),
              label: 'Quarterly',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Yearly',
            ),
          ],
        ),
      ],
    );
  }
}

