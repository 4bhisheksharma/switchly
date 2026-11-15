import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../core/widgets/tile_icon.dart';
import '../data/age_calculator.dart';
import '../data/bs_format.dart';

enum AgeInputMode { bs, ad }

/// An interactive card allowing users to calculate their exact age,
/// next birthday countdown, and life statistics using either BS or AD birth dates.
class AgeCalculatorCard extends StatefulWidget {
  const AgeCalculatorCard({
    super.key,
    required this.nepali,
    this.initialBirthDateBs,
  });

  final bool nepali;
  final NepaliDateTime? initialBirthDateBs;

  @override
  State<AgeCalculatorCard> createState() => _AgeCalculatorCardState();
}

class _AgeCalculatorCardState extends State<AgeCalculatorCard> {
  final NepaliDateTime _todayBs = DateTime.now().toNepaliDateTime();
  final DateTime _todayAd = DateTime.now();

  AgeInputMode _mode = AgeInputMode.bs;

  late int _selectedBsYear;
  late int _selectedBsMonth;
  late int _selectedBsDay;

  late DateTime _selectedAdDate;
  AgeResult? _result;

  @override
  void initState() {
    super.initState();
    // Default to a sensible initial birth date, e.g. 20 years ago
    final defaultBs = widget.initialBirthDateBs ??
        NepaliDateTime(
          _todayBs.year - 20,
          _todayBs.month,
          _todayBs.day > 28 ? 28 : _todayBs.day,
        );

    _selectedBsYear = defaultBs.year;
    _selectedBsMonth = defaultBs.month;
    _selectedBsDay = defaultBs.day;
    _selectedAdDate = defaultBs.toDateTime();

    _recalculate();
  }

  void _recalculate() {
    if (_mode == AgeInputMode.bs) {
      final maxDays = NepaliDateTime(_selectedBsYear, _selectedBsMonth).totalDays;
      if (_selectedBsDay > maxDays) {
        _selectedBsDay = maxDays;
      }
      final dobBs = NepaliDateTime(_selectedBsYear, _selectedBsMonth, _selectedBsDay);
      _selectedAdDate = dobBs.toDateTime();
      _result = AgeCalculator.calculateFromBs(dobBs, asOfBs: _todayBs);
    } else {
      _result = AgeCalculator.calculateFromAd(_selectedAdDate, asOfAd: _todayAd);
      if (_result != null) {
        _selectedBsYear = _result!.dobBs.year;
        _selectedBsMonth = _result!.dobBs.month;
        _selectedBsDay = _result!.dobBs.day;
      }
    }
  }

  Future<void> _pickAdDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedAdDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: widget.nepali ? 'जन्म मिति (AD) छान्नुहोस्' : 'Select Birth Date (AD)',
    );
    if (picked == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAdDate = picked;
      _recalculate();
    });
  }

  void _showBsPickerModal({
    required String title,
    required List<int> items,
    required int selected,
    required ValueChanged<int> onSelected,
    String Function(int)? itemLabel,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Symbols.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final val = items[index];
                      final isSelected = val == selected;
                      final label = itemLabel != null ? itemLabel(val) : BsFormat.digits(val, widget.nepali);
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: colors.primaryContainer.withValues(alpha: 0.3),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? colors.primary : colors.onSurface,
                          ),
                        ),
                        trailing: isSelected ? Icon(Symbols.check_rounded, color: colors.primary) : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelected(val);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _pickBsYear() {
    final years = List<int>.generate(_todayBs.year - 1970 + 1, (i) => _todayBs.year - i);
    _showBsPickerModal(
      title: widget.nepali ? 'वर्ष छान्नुहोस् (Year)' : 'Select Year (BS)',
      items: years,
      selected: _selectedBsYear,
      onSelected: (y) {
        setState(() {
          _selectedBsYear = y;
          _recalculate();
        });
      },
    );
  }

  void _pickBsMonth() {
    final months = List<int>.generate(12, (i) => i + 1);
    _showBsPickerModal(
      title: widget.nepali ? 'महिना छान्नुहोस् (Month)' : 'Select Month (BS)',
      items: months,
      selected: _selectedBsMonth,
      itemLabel: (m) => '${BsFormat.digits(m, widget.nepali)}. ${BsFormat.month(m, widget.nepali)}',
      onSelected: (m) {
        setState(() {
          _selectedBsMonth = m;
          _recalculate();
        });
      },
    );
  }

  void _pickBsDay() {
    final maxDays = NepaliDateTime(_selectedBsYear, _selectedBsMonth).totalDays;
    final days = List<int>.generate(maxDays, (i) => i + 1);
    _showBsPickerModal(
      title: widget.nepali ? 'गते छान्नुहोस् (Day)' : 'Select Day (BS)',
      items: days,
      selected: _selectedBsDay,
      onSelected: (d) {
        setState(() {
          _selectedBsDay = d;
          _recalculate();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final nepali = widget.nepali;

    final result = _result;

    return Card(
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                const TileIcon(Symbols.cake_rounded, active: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nepali ? 'उमेर क्यालकुलेटर' : 'Age Calculator',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        nepali ? 'वि.सं. तथा ई.सं. दुवैमा यकिन उमेर' : 'Exact age breakdown in BS & AD',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Selector: BS vs AD
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeTab(
                      label: nepali ? 'वि.सं. (BS)' : 'Bikram Sambat (BS)',
                      selected: _mode == AgeInputMode.bs,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _mode = AgeInputMode.bs;
                          _recalculate();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _ModeTab(
                      label: nepali ? 'ई.सं. (AD)' : 'Gregorian (AD)',
                      selected: _mode == AgeInputMode.ad,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _mode = AgeInputMode.ad;
                          _recalculate();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date Input Controls
            if (_mode == AgeInputMode.bs) ...[
              Text(
                nepali ? 'जन्म मिति छान्नुहोस्:' : 'Select Birth Date (BS):',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _PickerButton(
                      label: nepali ? 'वर्ष' : 'Year',
                      value: BsFormat.digits(_selectedBsYear, nepali),
                      onTap: _pickBsYear,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: _PickerButton(
                      label: nepali ? 'महिना' : 'Month',
                      value: BsFormat.month(_selectedBsMonth, nepali),
                      onTap: _pickBsMonth,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _PickerButton(
                      label: nepali ? 'गते' : 'Day',
                      value: BsFormat.digits(_selectedBsDay, nepali),
                      onTap: _pickBsDay,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                nepali ? 'जन्म मिति (AD) छान्नुहोस्:' : 'Select Birth Date (AD):',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickAdDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.event_rounded, size: 20, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          MaterialLocalizations.of(context).formatFullDate(_selectedAdDate),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(Symbols.edit_calendar_rounded, size: 18, color: colors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Equivalent Date Badge
            if (result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.sync_alt_rounded, size: 16, color: colors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mode == AgeInputMode.bs
                            ? 'AD: ${MaterialLocalizations.of(context).formatFullDate(result.dobAd)} (${result.birthWeekday(nepali)})'
                            : 'BS: ${BsFormat.date(result.dobBs, nepali)} (${result.birthWeekday(nepali)})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            // Results Section
            if (result == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.info_rounded, color: colors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nepali ? 'जन्म मिति भविष्यको हुनुहुँदैन।' : 'Birth date cannot be in the future.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Primary Age Hero Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryContainer.withValues(alpha: 0.7),
                      colors.primaryContainer.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          nepali ? 'तपाईंको उमेर' : 'YOUR CURRENT AGE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                        const Spacer(),
                        if (result.isTodayBirthday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nepali ? '🎉 आज जन्मदिन!' : '🎉 Birthday Today!',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Large Units Display (Years, Months, Days)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        _AgeUnitBox(
                          value: BsFormat.digits(result.years, nepali),
                          unit: nepali ? 'वर्ष' : 'Years',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('·', style: TextStyle(color: colors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        _AgeUnitBox(
                          value: BsFormat.digits(result.months, nepali),
                          unit: nepali ? 'महिना' : 'Months',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('·', style: TextStyle(color: colors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        _AgeUnitBox(
                          value: BsFormat.digits(result.days, nepali),
                          unit: nepali ? 'दिन' : 'Days',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Next Birthday Countdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Symbols.celebration_rounded, size: 20, color: colors.onTertiaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nepali ? 'आगामी जन्मदिन' : 'Next Birthday',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result.nextBirthdayCountdown(nepali),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            '${BsFormat.date(result.nextBirthdayBs, nepali)} (${result.nextBirthdayWeekday(nepali)})',
                            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Life Summary Statistics Grid (2x2)
              Row(
                children: [
                  Expanded(
                    child: _StatMiniCard(
                      icon: Symbols.today_rounded,
                      title: nepali ? 'जम्मा दिन' : 'Total Days',
                      value: BsFormat.digits(result.totalDays, nepali),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatMiniCard(
                      icon: Symbols.view_week_rounded,
                      title: nepali ? 'जम्मा हप्ता' : 'Total Weeks',
                      value: BsFormat.digits(result.totalWeeks, nepali),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatMiniCard(
                      icon: Symbols.calendar_month_rounded,
                      title: nepali ? 'जम्मा महिना' : 'Total Months',
                      value: BsFormat.digits(result.totalMonths, nepali),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatMiniCard(
                      icon: Symbols.event_seat_rounded,
                      title: nepali ? 'जन्म बार' : 'Born on',
                      value: result.birthWeekday(nepali),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Copy Report Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.shareText(nepali)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(nepali ? 'उमेर विवरण प्रतिलिपि गरियो' : 'Age details copied to clipboard')),
                    );
                  },
                  icon: const Icon(Symbols.content_copy_rounded, size: 18),
                  label: Text(nepali ? 'उमेर विवरण प्रतिलिपि गर्नुहोस्' : 'Copy Age Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Symbols.arrow_drop_down_rounded, size: 18, color: colors.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeUnitBox extends StatelessWidget {
  const _AgeUnitBox({
    required this.value,
    required this.unit,
  });

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.primary,
          ),
        ),
        Text(
          unit,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
