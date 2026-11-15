import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/select_chip.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../setup/presentation/add_tiles.dart';
import '../data/bs_format.dart';
import '../data/bs_patro.dart';
import 'age_calculator_card.dart';

/// Today's BS date, a month grid, and AD → BS conversion.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final NepaliDateTime _today = DateTime.now().toNepaliDateTime();
  late NepaliDateTime _month = NepaliDateTime(_today.year, _today.month);

  void _shiftMonth(int delta) {
    var month = _month.month + delta;
    var year = _month.year;
    if (month < 1) {
      month = 12;
      year--;
    } else if (month > 12) {
      month = 1;
      year++;
    }
    HapticFeedback.selectionClick();
    setState(() => _month = NepaliDateTime(year, month));
  }

  Future<void> _convert() async {
    final nepali = context.read<BsScriptCubit>().state;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1944),
      lastDate: DateTime(2090),
      helpText: 'Pick an AD date',
    );
    if (picked == null || !mounted) return;
    final bs = picked.toNepaliDateTime();
    _showDate(bs, picked, nepali);
  }

  void _openAgeCalculatorSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final nepali = context.watch<BsScriptCubit>().state;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AgeCalculatorCard(nepali: nepali),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDate(NepaliDateTime bs, DateTime ad, bool nepali) {
    final text = BsFormat.date(bs, nepali);
    final patro = BsPatro.get(bs.year, bs.month, bs.day);
    final tithi = patro.tithi(nepali);
    final holiday = patro.holiday(nepali);
    final isHoliday = patro.isHoliday;
    final events = patro.events(nepali);

    final copyFull = [
      text,
      if (tithi != null) (nepali ? 'तिथि: $tithi' : 'Tithi: $tithi'),
      if (isHoliday && holiday != null) (nepali ? 'सार्वजनिक बिदा: $holiday' : 'Public Holiday: $holiday'),
      if (!isHoliday && events.isNotEmpty) (nepali ? 'चाडपर्व: ${events.join(", ")}' : 'Events: ${events.join(", ")}'),
      'AD: ${MaterialLocalizations.of(context).formatFullDate(ad)}',
    ].join('\n');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${BsFormat.weekday(bs, nepali)} · ${MaterialLocalizations.of(context).formatFullDate(ad)}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (isHoliday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        nepali ? 'सार्वजनिक बिदा' : 'Public Holiday',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (tithi != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.nights_stay_rounded, size: 20, color: colors.primary),
                      const SizedBox(width: 10),
                      Text(
                        nepali ? 'तिथि' : 'Tithi',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tithi,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (events.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHoliday ? colors.errorContainer.withValues(alpha: 0.3) : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isHoliday ? colors.error.withValues(alpha: 0.4) : colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isHoliday ? Symbols.event_busy_rounded : Symbols.celebration_rounded,
                            size: 20,
                            color: isHoliday ? colors.error : colors.secondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isHoliday
                                ? (nepali ? 'सार्वजनिक बिदा' : 'Public Holiday')
                                : (nepali ? 'चाडपर्व तथा दिवस' : 'Events & Festivals'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isHoliday ? colors.error : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final event in events)
                        Padding(
                          padding: const EdgeInsets.only(left: 30, bottom: 4),
                          child: Text(
                            '• $event',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isHoliday ? FontWeight.bold : FontWeight.w500,
                              color: isHoliday ? colors.error : colors.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: copyFull));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(nepali ? 'मिति तथा विवरण प्रतिलिपि गरियो' : 'Date details copied')),
                    );
                  },
                  icon: const Icon(Symbols.content_copy_rounded, size: 20),
                  label: Text(nepali ? 'विवरण प्रतिलिपि गर्नुहोस्' : 'Copy Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestAddWidget(BuildContext context, [String widget = 'nepali_date']) async {
    final channel = context.read<QsChannel>();
    final success = await channel.requestPinWidget(widget);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Widget prompt displayed. Place it on your home screen!'
              : 'To add the widget, touch & hold an empty area on your home screen and choose Switchly.',
        ),
      ),
    );
  }

  void _showWidgetPreview(
    BuildContext context, {
    required String title,
    required String widgetId,
    required Widget previewWidget,
    required String subtitle,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              // Simulated Home Screen Wallpaper Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF111827)],
                  ),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: previewWidget,
                ),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FeaturePill(icon: Symbols.aspect_ratio_rounded, label: 'Freely resizable'),
                  _FeaturePill(icon: Symbols.update_rounded, label: 'Auto rolls at midnight'),
                  _FeaturePill(icon: Symbols.touch_app_rounded, label: 'Tap to open calendar'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _requestAddWidget(context, widgetId);
                  },
                  icon: const Icon(Symbols.add_to_home_screen_rounded),
                  label: const Text('Add to Home Screen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nepali = context.watch<BsScriptCubit>().state;
    final adToday = MaterialLocalizations.of(context).formatFullDate(DateTime.now());

    final todayPatro = BsPatro.get(_today.year, _today.month, _today.day);
    final todayTithi = todayPatro.tithi(nepali);
    final todayHoliday = todayPatro.holiday(nepali);
    final todayEvents = todayPatro.events(nepali);

    final heroLabel = [
      BsFormat.weekday(_today, nepali),
      ?todayTithi,
    ].join(' · ');

    final heroDetail = [
      if (todayPatro.isHoliday && todayHoliday != null)
        (nepali ? 'सार्वजनिक बिदा: $todayHoliday' : 'Holiday: $todayHoliday')
      else if (todayEvents.isNotEmpty)
        todayEvents.first,
      adToday,
    ].join(' · ');

    final copyFullToday = [
      BsFormat.date(_today, nepali),
      if (todayTithi != null) '($todayTithi)',
      if (todayHoliday != null) '· $todayHoliday',
    ].join(' ');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Nepali date')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverList.list(
              children: [
                HeroStatusCard(
                  icon: Symbols.calendar_month_rounded,
                  label: heroLabel,
                  value: BsFormat.date(_today, nepali),
                  detail: heroDetail,
                  active: true,
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: copyFullToday));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date copied')));
                        },
                        icon: const Icon(Symbols.content_copy_rounded, size: 20),
                        label: const Text('Copy'),
                      ),
                      if (canRequestAddTile(context)) const AddTileButton(bsDateTile, onGradient: true),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        onPressed: () => _requestAddWidget(context, 'nepali_date'),
                        icon: const Icon(Symbols.widgets_rounded, size: 20),
                        label: const Text('Add Widget'),
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Script'),
                Wrap(
                  spacing: 8,
                  children: [
                    SelectChip(
                      label: 'नेपाली',
                      selected: nepali,
                      onTap: () => context.read<BsScriptCubit>().setNepali(true),
                    ),
                    SelectChip(
                      label: 'English',
                      selected: !nepali,
                      onTap: () => context.read<BsScriptCubit>().setNepali(false),
                    ),
                  ],
                ),
                SectionHeader(
                  'Calendar',
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: _openAgeCalculatorSheet,
                        icon: const Icon(Symbols.cake_rounded, size: 18),
                        label: Text(nepali ? 'उमेर' : 'Age'),
                      ),
                      TextButton.icon(
                        onPressed: _convert,
                        icon: const Icon(Symbols.swap_horiz_rounded, size: 18),
                        label: const Text('Convert AD'),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                    child: _MonthGrid(
                      month: _month,
                      today: _today,
                      nepali: nepali,
                      onPrevious: () => _shiftMonth(-1),
                      onNext: () => _shiftMonth(1),
                      onDayTap: (day) => _showDate(day, day.toDateTime(), nepali),
                    ),
                  ),
                ),
                _MonthEventsList(
                  month: _month,
                  nepali: nepali,
                  onDayTap: (day) => _showDate(day, day.toDateTime(), nepali),
                ),
                const SizedBox(height: 8),
                SectionHeader(
                  nepali ? 'उमेर क्यालकुलेटर' : 'Age calculator',
                  subtitle: nepali
                      ? 'वि.सं. तथा ई.सं. दुवैमा यकिन उमेर, आगामी जन्मदिन र जीवन तथ्याङ्क।'
                      : 'Exact age, upcoming birthday countdown & life statistics in BS or AD.',
                ),
                AgeCalculatorCard(nepali: nepali),
                const SectionHeader(
                  'Home screen widgets',
                  subtitle: 'Live interactive widgets for your launcher. Freely resizable & auto-updating.',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const TileIcon(Symbols.calendar_today_rounded, active: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Standard Widget (4x2)',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Freely resizable · Adapts to any size on your home screen',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Exact live preview of the standard widget
                        GestureDetector(
                          onTap: () => _showWidgetPreview(
                            context,
                            title: 'Nepali Date (Standard)',
                            widgetId: 'nepali_date',
                            previewWidget: _NepaliDateStandardPreview(today: _today, nepali: nepali),
                            subtitle: 'Spacious card with BS day badge, month, year, weekday & AD date.',
                          ),
                          child: _NepaliDateStandardPreview(today: _today, nepali: nepali),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showWidgetPreview(
                                context,
                                title: 'Nepali Date (Standard)',
                                widgetId: 'nepali_date',
                                previewWidget: _NepaliDateStandardPreview(today: _today, nepali: nepali),
                                subtitle: 'Spacious card with BS day badge, month, year, weekday & AD date.',
                              ),
                              icon: const Icon(Symbols.preview_rounded, size: 18),
                              label: const Text('Preview'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _requestAddWidget(context, 'nepali_date'),
                              icon: const Icon(Symbols.add_to_home_screen_rounded, size: 18),
                              label: const Text('Add Widget'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const TileIcon(Symbols.calendar_view_day_rounded, active: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Compact Widget (2x2)',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Clean badge with large day number and month',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Exact live preview of the compact widget
                        Center(
                          child: GestureDetector(
                            onTap: () => _showWidgetPreview(
                              context,
                              title: 'Nepali Date (Compact)',
                              widgetId: 'nepali_date_compact',
                              previewWidget: _NepaliDateCompactPreview(today: _today, nepali: nepali),
                              subtitle: 'Compact badge showing current BS month, large day number, and weekday.',
                            ),
                            child: _NepaliDateCompactPreview(today: _today, nepali: nepali),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showWidgetPreview(
                                context,
                                title: 'Nepali Date (Compact)',
                                widgetId: 'nepali_date_compact',
                                previewWidget: _NepaliDateCompactPreview(today: _today, nepali: nepali),
                                subtitle: 'Compact badge showing current BS month, large day number, and weekday.',
                              ),
                              icon: const Icon(Symbols.preview_rounded, size: 18),
                              label: const Text('Preview'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _requestAddWidget(context, 'nepali_date_compact'),
                              icon: const Icon(Symbols.add_to_home_screen_rounded, size: 18),
                              label: const Text('Add Widget'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.nepali,
    required this.onPrevious,
    required this.onNext,
    required this.onDayTap,
  });

  /// Day 1 of the month shown.
  final NepaliDateTime month;
  final NepaliDateTime today;
  final bool nepali;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<NepaliDateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final leading = month.weekday - 1; // Empty cells before day 1 (Sunday-first grid).
    final days = month.totalDays;

    return Column(
      children: [
        Row(
          children: [
            IconButton(onPressed: onPrevious, icon: const Icon(Symbols.chevron_left_rounded)),
            Expanded(
              child: Text(
                '${BsFormat.month(month.month, nepali)} ${BsFormat.digits(month.year, nepali)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(onPressed: onNext, icon: const Icon(Symbols.chevron_right_rounded)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (i, label) in BsFormat.weekdayHeaders(nepali).indexed)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    // Saturday is the weekly holiday in Nepal.
                    color: i == 6 ? colors.error : colors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          childAspectRatio: 0.82,
          shrinkWrap: true,
          // Otherwise the grid adds the status-bar inset as an empty first row.
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var day = 1; day <= days; day++) ...[
              () {
                final patro = BsPatro.get(month.year, month.month, day);
                final isSat = (leading + day - 1) % 7 == 6;
                return _DayCell(
                  label: BsFormat.digits(day, nepali),
                  tithi: patro.tithi(nepali),
                  isToday: month.year == today.year && month.month == today.month && day == today.day,
                  isSaturday: isSat,
                  isHoliday: patro.isHoliday,
                  onTap: () => onDayTap(NepaliDateTime(month.year, month.month, day)),
                );
              }(),
            ],
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    this.tithi,
    required this.isToday,
    required this.isSaturday,
    required this.isHoliday,
    required this.onTap,
  });

  final String label;
  final String? tithi;
  final bool isToday;
  final bool isSaturday;
  final bool isHoliday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isOffDay = isSaturday || isHoliday;

    Color textColor;
    if (isToday) {
      textColor = colors.onPrimary;
    } else if (isOffDay) {
      textColor = colors.error;
    } else {
      textColor = colors.onSurface;
    }

    Color? tithiColor;
    if (isToday) {
      tithiColor = colors.onPrimary.withValues(alpha: 0.85);
    } else if (isOffDay) {
      tithiColor = colors.error.withValues(alpha: 0.8);
    } else {
      tithiColor = colors.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
      child: Material(
        color: isToday
            ? colors.primary
            : (isHoliday && !isSaturday ? colors.errorContainer.withValues(alpha: 0.25) : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday || isHoliday ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (tithi != null)
                Text(
                  tithi!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8.5,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    color: tithiColor,
                    height: 1.05,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthEventsList extends StatelessWidget {
  const _MonthEventsList({
    required this.month,
    required this.nepali,
    required this.onDayTap,
  });

  final NepaliDateTime month;
  final bool nepali;
  final ValueChanged<NepaliDateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final items = <({int day, String tithi, String title, bool isHoliday, List<String> events})>[];

    for (var d = 1; d <= month.totalDays; d++) {
      final p = BsPatro.get(month.year, month.month, d);
      final evs = p.events(nepali);
      if (p.isHoliday || evs.isNotEmpty) {
        items.add((
          day: d,
          tithi: p.tithi(nepali) ?? '',
          title: evs.isNotEmpty ? evs.first : (p.tithi(nepali) ?? ''),
          isHoliday: p.isHoliday,
          events: evs,
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          nepali ? 'यस महिनाका चाडपर्व तथा बिदाहरू' : 'Holidays & Events this Month',
          subtitle: nepali
              ? '${BsFormat.month(month.month, nepali)} महिनाका प्रमुख दिवस तथा सांस्कृतिक पर्वहरू'
              : 'Important days & cultural events in ${BsFormat.month(month.month, false)}',
        ),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 56,
              color: colors.outlineVariant.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final dayDate = NepaliDateTime(month.year, month.month, item.day);
              final weekdayStr = BsFormat.weekday(dayDate, nepali);

              return ListTile(
                onTap: () => onDayTap(dayDate),
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.isHoliday ? colors.errorContainer : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    BsFormat.digits(item.day, nepali),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: item.isHoliday ? colors.onErrorContainer : colors.onSurface,
                    ),
                  ),
                ),
                title: Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: item.isHoliday ? FontWeight.bold : FontWeight.w600,
                    color: item.isHoliday ? colors.error : colors.onSurface,
                  ),
                ),
                subtitle: Text(
                  [
                    weekdayStr,
                    if (item.tithi.isNotEmpty) item.tithi,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                trailing: item.isHoliday
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          nepali ? 'बिदा' : 'Holiday',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      )
                    : const Icon(Symbols.chevron_right_rounded, size: 18),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Pixel-perfect in-app preview of the standard 4x2 responsive Nepali Date widget.
class _NepaliDateStandardPreview extends StatelessWidget {
  const _NepaliDateStandardPreview({required this.today, required this.nepali});

  final NepaliDateTime today;
  final bool nepali;

  @override
  Widget build(BuildContext context) {
    final adDate = MaterialLocalizations.of(context).formatMediumDate(DateTime.now());
    final dayStr = BsFormat.digits(today.day, nepali);
    final monthYearStr = '${BsFormat.month(today.month, nepali)} ${BsFormat.digits(today.year, nepali)}';
    final weekdayStr = BsFormat.weekday(today, nepali);

    final patro = BsPatro.get(today.year, today.month, today.day);
    final extra = (patro.isHoliday ? patro.holiday(nepali) : null) ?? patro.tithi(nepali);
    final displayWeekday = extra != null ? '$weekdayStr · $extra' : weekdayStr;

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2C3E)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF23253B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF36395A)),
            ),
            alignment: Alignment.center,
            child: Text(
              dayStr,
              style: const TextStyle(
                color: Color(0xFF818CF8),
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthYearStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayWeekday,
                  style: const TextStyle(
                    color: Color(0xFFC4C2D6),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  adDate,
                  style: const TextStyle(
                    color: Color(0xFF8D8B9D),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pixel-perfect in-app preview of the compact 2x2 Nepali Date widget.
class _NepaliDateCompactPreview extends StatelessWidget {
  const _NepaliDateCompactPreview({required this.today, required this.nepali});

  final NepaliDateTime today;
  final bool nepali;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayStr = BsFormat.digits(today.day, nepali);
    final monthYearStr = '${BsFormat.month(today.month, nepali)} ${BsFormat.digits(today.year, nepali)}';
    final weekdayStr = BsFormat.weekday(today, nepali);
    final patro = BsPatro.get(today.year, today.month, today.day);
    final tithiStr = patro.tithi(nepali);
    final displayExtra = tithiStr ?? '${now.day} ${MaterialLocalizations.of(context).formatMonthYear(now).split(' ').first}';
    final subtitle = '$weekdayStr · $displayExtra';

    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2C3E)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            monthYearStr,
            style: const TextStyle(
              color: Color(0xFFC4C2D6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            dayStr,
            style: const TextStyle(
              color: Color(0xFF818CF8),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF8D8B9D),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
