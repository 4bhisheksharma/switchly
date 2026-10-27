import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/setup/bloc/setup_bloc.dart';
import '../features/setup/presentation/onboarding_screen.dart';

/// Root screen: onboarding until WRITE_SECURE_SETTINGS is granted, then home.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SetupBloc>().state;
    return switch (state.status) {
      SetupStatus.loading => const Scaffold(body: Center(child: CircularProgressIndicator())),
      SetupStatus.failure => const Scaffold(
          body: Center(child: Text('Switchly only runs on Android.')),
        ),
      SetupStatus.ready => state.hasPermission ? const HomeScreen() : const OnboardingScreen(),
    };
  }
}
