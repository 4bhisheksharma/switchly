import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/pref_keys.dart';

/// Whether tiles show a message at the top after a tap. Read by `BaseTile` in Kotlin.
class TileMessageCubit extends Cubit<bool> {
  TileMessageCubit() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(prefs.getBool(PrefKeys.showTileMessage) ?? true);
  }

  Future<void> set(bool show) async {
    emit(show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.showTileMessage, show);
  }
}
