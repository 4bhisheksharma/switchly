import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/select_chip.dart';
import '../../setup/presentation/add_tiles.dart';
import '../data/bs_format.dart';

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

  void _showDate(NepaliDateTime bs, DateTime ad, bool nepali) {
    final text = BsFormat.date(bs, nepali);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '${BsFormat.weekday(bs, nepali)} · ${MaterialLocalizations.of(context).formatFullDate(ad)}',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.of(context).pop();
                },
                icon: const Icon(Symbols.content_copy_rounded, size: 20),
                label: const Text('Copy BS date'),
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
                  label: BsFormat.weekday(_today, nepali),
                  value: BsFormat.date(_today, nepali),
                  detail: adToday,
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
                          Clipboard.setData(ClipboardData(text: BsFormat.date(_today, nepali)));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date copied')));
                        },
                        icon: const Icon(Symbols.content_copy_rounded, size: 20),
                        label: const Text('Copy'),
                      ),
                      if (canRequestAddTile(context)) const AddTileButton(bsDateTile, onGradient: true),
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
                  trailing: TextButton.icon(
                    onPressed: _convert,
                    icon: const Icon(Symbols.swap_horiz_rounded, size: 18),
                    label: const Text('Convert AD'),
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
          shrinkWrap: true,
          // Otherwise the grid adds the status-bar inset as an empty first row.
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var day = 1; day <= days; day++)
              _DayCell(
                label: BsFormat.digits(day, nepali),
                isToday: month.year == today.year && month.month == today.month && day == today.day,
                isSaturday: (leading + day - 1) % 7 == 6,
                onTap: () => onDayTap(NepaliDateTime(month.year, month.month, day)),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.label, required this.isToday, required this.isSaturday, required this.onTap});

  final String label;
  final bool isToday;
  final bool isSaturday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: isToday ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : null,
                color: isToday ? colors.onPrimary : (isSaturday ? colors.error : colors.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
