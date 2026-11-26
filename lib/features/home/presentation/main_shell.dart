import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../calendar/presentation/calendar_screen.dart';
import '../../payment_qr/presentation/payment_qr_screen.dart';
import '../../reminders/bloc/reminders_bloc.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'home_screen.dart';

/// Top-level app shell with a clean bottom navigation bar for frequently used features.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _selectTab(int index) {
    if (_index == index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final upcomingCount = context.select((RemindersBloc bloc) => bloc.state.upcomingCount);

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              onOpenCalendarTab: () => _selectTab(1),
              onOpenPayQrTab: () => _selectTab(2),
              onOpenRemindersTab: () => _selectTab(3),
            ),
            const CalendarScreen(),
            const PaymentQrScreen(),
            const RemindersScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: scheme.outlineVariant, width: 1),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _selectTab,
            destinations: [
              const NavigationDestination(
                icon: Icon(Symbols.dashboard_rounded),
                selectedIcon: Icon(Symbols.dashboard_rounded, fill: 1),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Symbols.calendar_month_rounded),
                selectedIcon: Icon(Symbols.calendar_month_rounded, fill: 1),
                label: 'Calendar',
              ),
              const NavigationDestination(
                icon: Icon(Symbols.qr_code_2_rounded),
                selectedIcon: Icon(Symbols.qr_code_2_rounded, fill: 1),
                label: 'Pay QR',
              ),
              NavigationDestination(
                icon: Badge.count(
                  count: upcomingCount,
                  isLabelVisible: upcomingCount > 0,
                  child: const Icon(Symbols.notifications_rounded),
                ),
                selectedIcon: Badge.count(
                  count: upcomingCount,
                  isLabelVisible: upcomingCount > 0,
                  child: const Icon(Symbols.notifications_active_rounded, fill: 1),
                ),
                label: 'Reminders',
              ),
              const NavigationDestination(
                icon: Icon(Symbols.settings_rounded),
                selectedIcon: Icon(Symbols.settings_rounded, fill: 1),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
