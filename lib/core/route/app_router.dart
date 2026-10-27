import 'package:flutter/material.dart';

/// Centralised navigation table for the app.
///
/// Wire this into your app with
/// `MaterialApp(onGenerateRoute: AppRouter.onGenerateRoute)` and navigate with
/// `Navigator.pushNamed(context, AppRouter.home)`.
class AppRouter {
  AppRouter._();

  static const String initial = '/';
  static const String home = '/home';
  static const String login = '/login';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
      case home:
        // TODO: return MaterialPageRoute(builder: (_) => const HomeScreen());
        return _placeholder('Home');
      case login:
        // TODO: return MaterialPageRoute(builder: (_) => const LoginScreen());
        return _placeholder('Login');
      default:
        return _placeholder('No route for ${settings.name}');
    }
  }

  static Route<dynamic> _placeholder(String title) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      ),
    );
  }
}
