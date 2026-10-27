import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/pref_keys.dart';

/// Month/weekday names and digits, matching `BikramSambat` in Kotlin so the app and the tile
/// read the same.
abstract final class BsFormat {
  static const _monthsEn = [
    'Baishakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', //
    'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra',
  ];
  static const _monthsNe = [
    'बैशाख', 'जेठ', 'असार', 'साउन', 'भदौ', 'असोज', //
    'कात्तिक', 'मंसिर', 'पुस', 'माघ', 'फागुन', 'चैत',
  ];

  /// Sunday first, matching [NepaliDateTime.weekday] (Sunday = 1).
  static const _weekdaysEn = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static const _weekdaysNe = ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार'];
  static const _weekdaysShortEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _weekdaysShortNe = ['आइत', 'सोम', 'मंगल', 'बुध', 'बिही', 'शुक्र', 'शनि'];

  static String month(int month, bool nepali) => (nepali ? _monthsNe : _monthsEn)[month - 1];

  static String weekday(NepaliDateTime date, bool nepali) => (nepali ? _weekdaysNe : _weekdaysEn)[date.weekday - 1];

  /// Column headers for a Sunday-first month grid.
  static List<String> weekdayHeaders(bool nepali) => nepali ? _weekdaysShortNe : _weekdaysShortEn;

  static String digits(int value, bool nepali) {
    final ascii = value.toString();
    if (!nepali) return ascii;
    return String.fromCharCodes(ascii.codeUnits.map((c) => 0x0966 + (c - 0x30)));
  }

  /// "कात्तिक ११, २०८३" / "Kartik 11, 2083".
  static String date(NepaliDateTime d, bool nepali) => '${month(d.month, nepali)} ${digits(d.day, nepali)}, ${digits(d.year, nepali)}';
}

/// Whether BS dates use Devanagari. Stored where the date tile reads it.
class BsScriptCubit extends Cubit<bool> {
  BsScriptCubit() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.bsConfig);
    if (raw == null) return;
    try {
      emit((jsonDecode(raw) as Map<String, Object?>)['nepali'] as bool? ?? true);
    } on Object {
      // Keep the default.
    }
  }

  Future<void> setNepali(bool nepali) async {
    emit(nepali);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.bsConfig, jsonEncode({'nepali': nepali}));
  }
}
