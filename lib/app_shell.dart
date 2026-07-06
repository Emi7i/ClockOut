import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/clock/bloc/clock_bloc.dart';
import '../features/clock/screens/alarm_ringing_screen.dart';
import '../features/clock/screens/clock_in_screen.dart';
import '../features/clock/screens/clocked_in_screen.dart';
import '../features/logs/bloc/logs_bloc.dart';
import '../features/logs/screens/logs_screen.dart';
import '../features/settings/bloc/settings_bloc.dart';
import '../features/settings/screens/settings_screen.dart';

/// ─────────────────────────────────────────────────────────────
///  APP SHELL
///  Top-level widget that owns navigation state and switches
///  between screens.  All BLoCs are provided here so they survive
///  tab changes.
///
///  Navigation map:
///    Tab 0  →  Clock In  /  Clocked In  (driven by ClockBloc state)
///    Tab 1  →  Logs
///    Settings is a sub-page pushed over any tab.
/// ─────────────────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int  _navIndex      = 0;
  bool _showSettings  = false;
  bool _ringingScreenOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync on app start
    context.read<ClockBloc>().add(const ClockStarted());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sync state whenever app comes back to foreground
      context.read<ClockBloc>().add(const ClockStarted());
    }
  }

  void _onNavTap(int index) {
    // Log entries can be added (clock out) or deleted (settings) from other
    // tabs, so refresh the cached list whenever the Logs tab is opened.
    if (index == 1 && _navIndex != 1) {
      context.read<LogsBloc>().add(const LogsStarted());
    }
    setState(() {
      _navIndex     = index;
      _showSettings = false;
    });
  }

  void _openSettings()  => setState(() => _showSettings = true);
  void _closeSettings() => setState(() => _showSettings = false);

  bool _isRinging(ClockState state) => state is ClockActive && state.isRinging;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClockBloc, ClockState>(
      listenWhen: (previous, current) => _isRinging(previous) != _isRinging(current),
      listener: (context, state) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (_isRinging(state) && !_ringingScreenOpen) {
          _ringingScreenOpen = true;
          navigator
              .push(MaterialPageRoute(
                builder: (_) => const AlarmRingingScreen(),
                fullscreenDialog: true,
              ))
              .then((_) => _ringingScreenOpen = false);
        } else if (!_isRinging(state) && _ringingScreenOpen) {
          _ringingScreenOpen = false;
          navigator.pop();
        }
      },
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Settings overlay ──────────────────────────────────
    if (_showSettings) {
      return SettingsScreen(
        onBack:    _closeSettings,
        navIndex:  _navIndex,
        onNavTap:  _onNavTap,
      );
    }

    // ── Tab content ───────────────────────────────────────
    return switch (_navIndex) {
      0 => _ClockTabSwitcher(
           onSettingsTap: _openSettings,
           navIndex:      _navIndex,
           onNavTap:      _onNavTap,
         ),
      1 => LogsScreen(
           onSettingsTap: _openSettings,
           navIndex:      _navIndex,
           onNavTap:      _onNavTap,
         ),
      _ => _ClockTabSwitcher(
           onSettingsTap: _openSettings,
           navIndex:      _navIndex,
           onNavTap:      _onNavTap,
         ),
    };
  }
}

/// Switches between [ClockInScreen] and [ClockedInScreen]
/// based on [ClockBloc] state.
class _ClockTabSwitcher extends StatelessWidget {
  final VoidCallback      onSettingsTap;
  final int               navIndex;
  final ValueChanged<int> onNavTap;

  const _ClockTabSwitcher({
    required this.onSettingsTap,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClockBloc, ClockState>(
      builder: (context, state) => switch (state) {
        ClockActive() => ClockedInScreen(
            onSettingsTap: onSettingsTap,
            navIndex:      navIndex,
            onNavTap:      onNavTap,
          ),
        ClockIdle() => ClockInScreen(
            onSettingsTap: onSettingsTap,
            navIndex:      navIndex,
            onNavTap:      onNavTap,
          ),
        ClockLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ClockError(message: var msg) => Scaffold(
            body: Center(child: Text(msg)),
          ),
      },
    );
  }
}
