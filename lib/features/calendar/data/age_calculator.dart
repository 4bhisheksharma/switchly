import 'package:nepali_utils/nepali_utils.dart';

import 'bs_format.dart';

/// Results of an age calculation breakdown.
class AgeResult {
  const AgeResult({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.totalWeeks,
    required this.totalMonths,
    required this.totalHours,
    required this.birthWeekdayEn,
    required this.birthWeekdayNe,
    required this.nextBirthdayBs,
    required this.nextBirthdayAd,
    required this.nextBirthdayMonths,
    required this.nextBirthdayDays,
    required this.nextBirthdayDaysTotal,
    required this.nextBirthdayWeekdayEn,
    required this.nextBirthdayWeekdayNe,
    required this.isTodayBirthday,
    required this.dobBs,
    required this.dobAd,
  });

  final int years;
  final int months;
  final int days;

  final int totalDays;
  final int totalWeeks;
  final int totalMonths;
  final int totalHours;

  final String birthWeekdayEn;
  final String birthWeekdayNe;

  final NepaliDateTime nextBirthdayBs;
  final DateTime nextBirthdayAd;
  final int nextBirthdayMonths;
  final int nextBirthdayDays;
  final int nextBirthdayDaysTotal;
  final String nextBirthdayWeekdayEn;
  final String nextBirthdayWeekdayNe;

  final bool isTodayBirthday;

  final NepaliDateTime dobBs;
  final DateTime dobAd;

  /// Formatted main age string, e.g. "25 Years, 8 Months, 12 Days" or "२५ वर्ष, ८ महिना, १२ दिन".
  String formattedAge(bool nepali) {
    final yStr = nepali ? '${BsFormat.digits(years, nepali)} वर्ष' : '$years ${years == 1 ? "Year" : "Years"}';
    final mStr = nepali ? '${BsFormat.digits(months, nepali)} महिना' : '$months ${months == 1 ? "Month" : "Months"}';
    final dStr = nepali ? '${BsFormat.digits(days, nepali)} दिन' : '$days ${days == 1 ? "Day" : "Days"}';
    return '$yStr, $mStr, $dStr';
  }

  /// Compact age string, e.g. "25y 8m 12d" / "२५व ८म १२दि".
  String compactAge(bool nepali) {
    if (nepali) {
      return '${BsFormat.digits(years, nepali)}व ${BsFormat.digits(months, nepali)}म ${BsFormat.digits(days, nepali)}दि';
    }
    return '${years}y ${months}m ${days}d';
  }

  /// Next birthday countdown description.
  String nextBirthdayCountdown(bool nepali) {
    if (isTodayBirthday) {
      return nepali ? 'आज जन्मदिन हो! 🎂 शुभकामना!' : 'Today is your birthday! 🎂 Happy Birthday!';
    }
    if (nextBirthdayDaysTotal == 1) {
      return nepali ? 'भोलि जन्मदिन! (१ दिन बाँकी)' : 'Tomorrow! (1 day left)';
    }

    final parts = <String>[];
    if (nextBirthdayMonths > 0) {
      parts.add(nepali
          ? '${BsFormat.digits(nextBirthdayMonths, nepali)} महिना'
          : '$nextBirthdayMonths ${nextBirthdayMonths == 1 ? "month" : "months"}');
    }
    if (nextBirthdayDays > 0) {
      parts.add(nepali
          ? '${BsFormat.digits(nextBirthdayDays, nepali)} दिन'
          : '$nextBirthdayDays ${nextBirthdayDays == 1 ? "day" : "days"}');
    }
    final timeStr = parts.join(nepali ? ', ' : ' and ');
    final totalDaysStr = nepali
        ? '(${BsFormat.digits(nextBirthdayDaysTotal, nepali)} दिन बाँकी)'
        : '($nextBirthdayDaysTotal days left)';
    return nepali ? '$timeStr पछि $totalDaysStr' : 'In $timeStr $totalDaysStr';
  }

  String birthWeekday(bool nepali) => nepali ? birthWeekdayNe : birthWeekdayEn;

  String nextBirthdayWeekday(bool nepali) => nepali ? nextBirthdayWeekdayNe : nextBirthdayWeekdayEn;

  /// Full copyable report.
  String shareText(bool nepali) {
    final buffer = StringBuffer();
    if (nepali) {
      buffer.writeln('🎂 उमेर विवरण (Age Details)');
      buffer.writeln('जन्म मिति (BS): ${BsFormat.date(dobBs, true)} (${birthWeekday(true)})');
      buffer.writeln('जन्म मिति (AD): ${dobAd.year}-${dobAd.month.toString().padLeft(2, '0')}-${dobAd.day.toString().padLeft(2, '0')}');
      buffer.writeln('उमेर: ${formattedAge(true)}');
      buffer.writeln('आगामी जन्मदिन: ${BsFormat.date(nextBirthdayBs, true)} (${nextBirthdayWeekday(true)})');
      buffer.writeln('बाँकी समय: ${nextBirthdayCountdown(true)}');
      buffer.writeln('जम्मा दिन: ${BsFormat.digits(totalDays, true)}');
      buffer.writeln('जम्मा हप्ता: ${BsFormat.digits(totalWeeks, true)}');
      buffer.writeln('जम्मा महिना: ${BsFormat.digits(totalMonths, true)}');
      buffer.writeln('जम्मा घण्टा: ${BsFormat.digits(totalHours, true)}');
    } else {
      buffer.writeln('🎂 Age Details');
      buffer.writeln('Date of Birth (BS): ${BsFormat.date(dobBs, false)} (${birthWeekday(false)})');
      buffer.writeln('Date of Birth (AD): ${dobAd.year}-${dobAd.month.toString().padLeft(2, '0')}-${dobAd.day.toString().padLeft(2, '0')}');
      buffer.writeln('Age: ${formattedAge(false)}');
      buffer.writeln('Next Birthday: ${BsFormat.date(nextBirthdayBs, false)} (${nextBirthdayWeekday(false)})');
      buffer.writeln('Countdown: ${nextBirthdayCountdown(false)}');
      buffer.writeln('Total Days: $totalDays');
      buffer.writeln('Total Weeks: $totalWeeks');
      buffer.writeln('Total Months: $totalMonths');
      buffer.writeln('Total Hours: $totalHours');
    }
    return buffer.toString().trim();
  }
}

/// Computes age and birthday countdown in Bikram Sambat (BS) and Gregorian (AD).
abstract final class AgeCalculator {
  static const _weekdaysEn = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static const _weekdaysNe = ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार'];

  /// Calculates age based on a Bikram Sambat birth date.
  /// [asOfBs] defaults to the current BS date.
  static AgeResult? calculateFromBs(NepaliDateTime birthDate, {NepaliDateTime? asOfBs}) {
    final now = asOfBs ?? DateTime.now().toNepaliDateTime();
    final nowAd = now.toDateTime();
    final birthDateAd = birthDate.toDateTime();

    // Verify not in the future
    if (birthDate.isAfter(now)) {
      return null;
    }

    var years = now.year - birthDate.year;
    var months = now.month - birthDate.month;
    var days = now.day - birthDate.day;

    if (days < 0) {
      var prevMonth = now.month - 1;
      var prevYear = now.year;
      if (prevMonth < 1) {
        prevMonth = 12;
        prevYear -= 1;
      }
      final daysInPrevMonth = NepaliDateTime(prevYear, prevMonth).totalDays;
      days += daysInPrevMonth;
      months -= 1;
    }

    if (months < 0) {
      months += 12;
      years -= 1;
    }

    // Total metrics using AD timeline for precise 24h day measurement
    final totalDays = nowAd.difference(DateTime(birthDateAd.year, birthDateAd.month, birthDateAd.day)).inDays;
    final totalWeeks = totalDays ~/ 7;
    final totalMonths = years * 12 + months;
    final totalHours = totalDays * 24;

    // Birth weekday
    final birthWeekdayIdx = (birthDate.weekday - 1).clamp(0, 6);
    final birthWeekdayEn = _weekdaysEn[birthWeekdayIdx];
    final birthWeekdayNe = _weekdaysNe[birthWeekdayIdx];

    // Next Birthday calculation in BS
    final thisYearMaxDays = NepaliDateTime(now.year, birthDate.month).totalDays;
    final thisYearBirthDay = birthDate.day > thisYearMaxDays ? thisYearMaxDays : birthDate.day;
    final thisYearBirthday = NepaliDateTime(now.year, birthDate.month, thisYearBirthDay);

    final isTodayBirthday = now.month == birthDate.month && now.day == birthDate.day;

    NepaliDateTime nextBirthdayBs;
    if (isTodayBirthday) {
      nextBirthdayBs = thisYearBirthday;
    } else if (thisYearBirthday.isBefore(now)) {
      // Birthday already passed this year, next is next year
      final nextYear = now.year + 1;
      final nextYearMaxDays = NepaliDateTime(nextYear, birthDate.month).totalDays;
      final nextYearBirthDay = birthDate.day > nextYearMaxDays ? nextYearMaxDays : birthDate.day;
      nextBirthdayBs = NepaliDateTime(nextYear, birthDate.month, nextYearBirthDay);
    } else {
      nextBirthdayBs = thisYearBirthday;
    }

    final nextBirthdayAd = nextBirthdayBs.toDateTime();
    final todayAdJustDate = DateTime(nowAd.year, nowAd.month, nowAd.day);
    final nextBirthdayAdJustDate = DateTime(nextBirthdayAd.year, nextBirthdayAd.month, nextBirthdayAd.day);
    final nextBirthdayDaysTotal = isTodayBirthday ? 0 : nextBirthdayAdJustDate.difference(todayAdJustDate).inDays;

    // Remaining months & days to next birthday in BS calendar
    int nbMonths;
    int nbDays;
    if (isTodayBirthday) {
      nbMonths = 0;
      nbDays = 0;
    } else {
      nbMonths = nextBirthdayBs.month - now.month;
      nbDays = nextBirthdayBs.day - now.day;
      if (nextBirthdayBs.year > now.year) {
        nbMonths += 12;
      }
      if (nbDays < 0) {
        var prevMonth = nextBirthdayBs.month - 1;
        var prevYear = nextBirthdayBs.year;
        if (prevMonth < 1) {
          prevMonth = 12;
          prevYear -= 1;
        }
        final daysInPrev = NepaliDateTime(prevYear, prevMonth).totalDays;
        nbDays += daysInPrev;
        nbMonths -= 1;
      }
    }

    final nextWeekdayIdx = (nextBirthdayBs.weekday - 1).clamp(0, 6);
    final nextBirthdayWeekdayEn = _weekdaysEn[nextWeekdayIdx];
    final nextBirthdayWeekdayNe = _weekdaysNe[nextWeekdayIdx];

    return AgeResult(
      years: years,
      months: months,
      days: days,
      totalDays: totalDays,
      totalWeeks: totalWeeks,
      totalMonths: totalMonths,
      totalHours: totalHours,
      birthWeekdayEn: birthWeekdayEn,
      birthWeekdayNe: birthWeekdayNe,
      nextBirthdayBs: nextBirthdayBs,
      nextBirthdayAd: nextBirthdayAd,
      nextBirthdayMonths: nbMonths,
      nextBirthdayDays: nbDays,
      nextBirthdayDaysTotal: nextBirthdayDaysTotal,
      nextBirthdayWeekdayEn: nextBirthdayWeekdayEn,
      nextBirthdayWeekdayNe: nextBirthdayWeekdayNe,
      isTodayBirthday: isTodayBirthday,
      dobBs: birthDate,
      dobAd: birthDateAd,
    );
  }

  /// Calculates age based on a Gregorian (AD) birth date.
  static AgeResult? calculateFromAd(DateTime birthDateAd, {DateTime? asOfAd}) {
    final birthDateBs = birthDateAd.toNepaliDateTime();
    final asOfBs = asOfAd?.toNepaliDateTime();
    return calculateFromBs(birthDateBs, asOfBs: asOfBs);
  }
}

