import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/platform/qs_channel.dart';
import '../features/display/bloc/display_bloc.dart';
import '../features/display/data/display_repository.dart';
import '../features/dns/bloc/dns_bloc.dart';
import '../features/network/bloc/network_bloc.dart';
import '../features/network/data/network_repository.dart';
import '../features/profiles/bloc/profiles_bloc.dart';
import '../features/profiles/data/profile_models.dart';
import '../features/quick_texts/bloc/quick_texts_bloc.dart';
import '../features/quick_texts/data/quick_text.dart';
import '../features/dns/data/dns_repository.dart';
import '../features/setup/bloc/setup_bloc.dart';
import '../features/setup/data/setup_repository.dart';
import '../features/setup/presentation/permission_sheet.dart';
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
  late final DnsBloc _dnsBloc = DnsBloc(DnsRepository(widget.channel))
    ..add(const DnsStarted());
  late final DisplayBloc _displayBloc = DisplayBloc(DisplayRepository(widget.channel))
    ..add(const DisplayStarted());
  late final NetworkBloc _networkBloc = NetworkBloc(NetworkRepository(widget.channel))
    ..add(const NetworkStarted());
  late final QuickTextsBloc _quickTextsBloc = QuickTextsBloc(const QuickTextsRepository())
    ..add(const QuickTextsStarted());
  late final ProfilesBloc _profilesBloc = ProfilesBloc(ProfilesRepository(widget.channel))
    ..add(const ProfilesStarted());
  late final StreamSubscription<String> _launchSub;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _launchSub = widget.channel.launchRoutes.listen(_handleLaunchRoute);
    // Permission grants and tile taps happen outside the app, so re-read on every return.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _setupBloc.add(const SetupPermissionCheckRequested());
        _dnsBloc.add(const DnsLiveStateRefreshed());
        _displayBloc.add(const DisplayRefreshed());
        _networkBloc.add(const NetworkRefreshed());
        _profilesBloc.add(const ProfilesRefreshed());
      },
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
    // Also closes any open sheet, so the target always ends up on top.
    navigator.popUntil((r) => r.isFirst);
    if (route == AppRouter.setupLaunch) {
      _setupBloc.add(const SetupPermissionCheckRequested());
      showPermissionSheet(navigator.overlay!.context);
    } else if (route.startsWith(AppRouter.tileLaunchPrefix)) {
      final page = AppRouter.routeForTile(route.substring(AppRouter.tileLaunchPrefix.length));
      if (page != null) navigator.pushNamed(page);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _launchSub.cancel();
    _setupBloc.close();
    _dnsBloc.close();
    _displayBloc.close();
    _networkBloc.close();
    _quickTextsBloc.close();
    _profilesBloc.close();
    widget.channel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _setupRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _setupBloc),
          BlocProvider.value(value: _dnsBloc),
          BlocProvider.value(value: _displayBloc),
          BlocProvider.value(value: _networkBloc),
          BlocProvider.value(value: _quickTextsBloc),
          BlocProvider.value(value: _profilesBloc),
        ],
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
