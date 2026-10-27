import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/platform/qs_channel.dart';
import '../features/setup/bloc/setup_bloc.dart';
import '../features/setup/data/setup_repository.dart';
import 'router.dart';
import 'theme.dart';

class SwitchlyApp extends StatefulWidget {
  const SwitchlyApp({super.key, required this.channel});

  final QsChannel channel;

  @override
  State<SwitchlyApp> createState() => _SwitchlyAppState();
}

class _SwitchlyAppState extends State<SwitchlyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final SetupRepository _setupRepository = SetupRepository(widget.channel);
  late final SetupBloc _setupBloc = SetupBloc(_setupRepository)
    ..add(const SetupStarted());
  late final StreamSubscription<String> _launchSub;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _launchSub = widget.channel.launchRoutes.listen(_handleLaunchRoute);
    // The user grants the permission outside the app, so re-check on every return.
    _lifecycle = AppLifecycleListener(
      onResume: () => _setupBloc.add(const SetupPermissionCheckRequested()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final route = await widget.channel.takeLaunchRoute();
      if (route != null) _handleLaunchRoute(route);
    });
  }

  /// Handles a tile tap (`/setup`) or long-press (`/tile/<id>`) that opened the app.
  void _handleLaunchRoute(String route) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    // The shell already shows onboarding when the permission is missing.
    navigator.popUntil((r) => r.isFirst);
    if (route == AppRouter.setupLaunch) {
      _setupBloc.add(const SetupPermissionCheckRequested());
    }
    // TODO(config-ui): push the matching config screen for AppRouter.tileLaunchPrefix routes.
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _launchSub.cancel();
    _setupBloc.close();
    widget.channel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _setupRepository,
      child: BlocProvider.value(
        value: _setupBloc,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Switchly',
          navigatorKey: _navigatorKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          initialRoute: AppRouter.root,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
