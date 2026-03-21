import 'package:flutter/material.dart';
import 'package:alpha/features/board/presentation/weekly_view_screen.dart';
import 'package:alpha/features/board/presentation/monthly_view_screen.dart';
import 'package:alpha/features/board/presentation/yearly_view_screen.dart';


/// Root shell with bottom navigation for weekly, monthly,
/// and yearly views.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  DateTime? _targetMonday;
  int _weekNavKey = 0;

  /// Called by monthly/yearly views to jump to a specific week.
  void _navigateToWeek(DateTime monday) {
    setState(() {
      _targetMonday = monday;
      _weekNavKey++;
      _currentIndex = 0;
    });
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return WeeklyViewScreen(
          key: ValueKey('week_$_weekNavKey'),
          initialMonday: _targetMonday,
        );
      case 1:
        return MonthlyViewScreen(onDayTap: _navigateToWeek);
      case 2:
        return YearlyViewScreen(onDayTap: _navigateToWeek);
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
          onDestinationSelected: (i) {
            setState(() {
              if (i == 0 && _currentIndex != 0) {
                // Reset to current week when returning via tab bar.
                _targetMonday = null;
                _weekNavKey++;
              }
              _currentIndex = i;
            });
          },
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
