import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/platform/qs_channel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SwitchlyApp(channel: QsChannel()));
}