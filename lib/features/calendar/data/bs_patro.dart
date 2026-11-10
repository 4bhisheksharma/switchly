import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';

/// Representation of Nepali patro metadata for a single Bikram Sambat day.
final class BsPatroDay {
  const BsPatroDay({
    required this.year,
    required this.month,
    required this.day,
    this.tithiNp,
    this.tithiEn,
    this.isHoliday = false,
    this.holidayNameNp,
    this.holidayNameEn,
    this.eventsNp = const [],
    this.eventsEn = const [],
  });

  final int year;
  final int month;
  final int day;

  final String? tithiNp;
  final String? tithiEn;

  final bool isHoliday;
  final String? holidayNameNp;
  final String? holidayNameEn;

  final List<String> eventsNp;
  final List<String> eventsEn;

  /// Returns localized tithi (e.g. "एकादशी" or "Ekadashi").
  String? tithi(bool nepali) => nepali ? tithiNp : tithiEn;

  /// Returns localized holiday/festival title if this is a holiday or has a primary event.
  String? holiday(bool nepali) => nepali ? holidayNameNp : holidayNameEn;

  /// Returns list of event names in the chosen script.
  List<String> events(bool nepali) => nepali ? eventsNp : eventsEn;

  /// Full descriptive text for subtitles or dialogs.
  String summary(bool nepali) {
    final parts = <String>[];
    final t = tithi(nepali);
    if (t != null && t.isNotEmpty) {
      parts.add(nepali ? 'तिथि: $t' : 'Tithi: $t');
    }
    final h = holiday(nepali);
    if (h != null && h.isNotEmpty) {
      parts.add(isHoliday ? (nepali ? 'बिदा: $h' : 'Holiday: $h') : h);
    }
    return parts.join(' · ');
  }
}

/// Provides lookup for tithi, holidays, and events using the verified `nepdate_patro` tables.
abstract final class BsPatro {
  static final Map<int, BsPatroDay> _cache = {};

  /// Retrieves the patro information for a given BS date.
  static BsPatroDay get(int year, int month, int day) {
    final key = year * 10000 + month * 100 + day;
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final nDate = NepaliDate.fromBs(year, month, day);
      final cInfo = info(nDate);

      final tithiNp = cInfo.tithi?.nepali;
      final tithiEn = cInfo.tithi?.english;

      final isHoliday = cInfo.isPublicHoliday;
      final eventsNp = cInfo.events.map((e) => e.nepali).toList();
      final eventsEn = cInfo.events.map((e) => e.english).toList();

      String? holidayNameNp;
      String? holidayNameEn;

      if (eventsNp.isNotEmpty) {
        holidayNameNp = eventsNp.first;
        holidayNameEn = eventsEn.first;
      }

      final result = BsPatroDay(
        year: year,
        month: month,
        day: day,
        tithiNp: tithiNp,
        tithiEn: tithiEn,
        isHoliday: isHoliday,
        holidayNameNp: holidayNameNp,
        holidayNameEn: holidayNameEn,
        eventsNp: eventsNp,
        eventsEn: eventsEn,
      );

      _cache[key] = result;
      return result;
    } catch (_) {
      return BsPatroDay(year: year, month: month, day: day);
    }
  }
}

