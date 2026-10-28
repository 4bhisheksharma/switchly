import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/screen_time_config.dart';
import '../data/screen_time_repository.dart';

sealed class ScreenTimeEvent extends Equatable {
  const ScreenTimeEvent();

  @override
  List<Object?> get props => [];
}

class ScreenTimeStarted extends ScreenTimeEvent {
  const ScreenTimeStarted();
}

class ScreenTimePermissionCheckRequested extends ScreenTimeEvent {
  const ScreenTimePermissionCheckRequested();
}

class ScreenTimeAppSelected extends ScreenTimeEvent {
  const ScreenTimeAppSelected(this.app, {this.slot = 1});

  final AppUsageItem app;
  final int slot;

  @override
  List<Object?> get props => [app.package, slot];
}

class ScreenTimeSlotAssigned extends ScreenTimeEvent {
  const ScreenTimeSlotAssigned(this.slot, this.app);

  final int slot;
  final AppUsageItem app;

  @override
  List<Object?> get props => [slot, app.package];
}

class ScreenTimeSlotRemoved extends ScreenTimeEvent {
  const ScreenTimeSlotRemoved(this.slot);

  final int slot;

  @override
  List<Object?> get props => [slot];
}

class ScreenTimeOpenOnTapToggled extends ScreenTimeEvent {
  const ScreenTimeOpenOnTapToggled(this.openAppOnTap, {this.slot = 1});

  final bool openAppOnTap;
  final int slot;

  @override
  List<Object?> get props => [openAppOnTap, slot];
}

class ScreenTimeSlotOpenOnTapToggled extends ScreenTimeEvent {
  const ScreenTimeSlotOpenOnTapToggled(this.slot, this.openAppOnTap);

  final int slot;
  final bool openAppOnTap;

  @override
  List<Object?> get props => [slot, openAppOnTap];
}

class ScreenTimeRefreshed extends ScreenTimeEvent {
  const ScreenTimeRefreshed();
}

class ScreenTimeState extends Equatable {
  const ScreenTimeState({
    this.hasPermission = false,
    this.slots = const [],
    this.slotTimes = const {},
    this.apps = const [],
    this.isLoading = false,
  });

  final bool hasPermission;
  final List<ScreenTimeConfig> slots;
  final Map<int, ({int millis, String formatted})> slotTimes;
  final List<AppUsageItem> apps;
  final bool isLoading;

  ScreenTimeConfig? get config => slots.where((c) => c.slot == 1).firstOrNull ?? slots.firstOrNull;

  int get currentAppMillis =>
      slotTimes[1]?.millis ?? (slots.isNotEmpty ? (slotTimes[slots.first.slot]?.millis ?? 0) : 0);

  String get currentAppFormatted =>
      slotTimes[1]?.formatted ??
      (slots.isNotEmpty ? (slotTimes[slots.first.slot]?.formatted ?? '0m') : '0m');

  ScreenTimeConfig? configForSlot(int slot) =>
      slots.where((c) => c.slot == slot).firstOrNull;

  ({int millis, String formatted}) timeForSlot(int slot) =>
      slotTimes[slot] ?? (millis: 0, formatted: '0m');

  int? slotForPackage(String package) =>
      slots.where((c) => c.packageName == package).firstOrNull?.slot;

  ScreenTimeState copyWith({
    bool? hasPermission,
    List<ScreenTimeConfig>? slots,
    Map<int, ({int millis, String formatted})>? slotTimes,
    List<AppUsageItem>? apps,
    bool? isLoading,
  }) {
    return ScreenTimeState(
      hasPermission: hasPermission ?? this.hasPermission,
      slots: slots ?? this.slots,
      slotTimes: slotTimes ?? this.slotTimes,
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        hasPermission,
        slots,
        slotTimes,
        apps,
        isLoading,
      ];
}

class ScreenTimeBloc extends Bloc<ScreenTimeEvent, ScreenTimeState> {
  ScreenTimeBloc(this._repository) : super(const ScreenTimeState()) {
    on<ScreenTimeStarted>(_onStarted);
    on<ScreenTimePermissionCheckRequested>(_onPermissionCheck);
    on<ScreenTimeAppSelected>(_onAppSelected);
    on<ScreenTimeSlotAssigned>(_onSlotAssigned);
    on<ScreenTimeSlotRemoved>(_onSlotRemoved);
    on<ScreenTimeOpenOnTapToggled>(_onOpenOnTapToggled);
    on<ScreenTimeSlotOpenOnTapToggled>(_onSlotOpenOnTapToggled);
    on<ScreenTimeRefreshed>(_onRefreshed);
  }

  final ScreenTimeRepository _repository;

  Future<void> _onStarted(
    ScreenTimeStarted event,
    Emitter<ScreenTimeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _loadFullData(emit);
  }

  Future<void> _onPermissionCheck(
    ScreenTimePermissionCheckRequested event,
    Emitter<ScreenTimeState> emit,
  ) async {
    final hasPerm = await _repository.hasUsageAccess();
    if (hasPerm != state.hasPermission) {
      await _loadFullData(emit);
    }
  }

  Future<void> _onAppSelected(
    ScreenTimeAppSelected event,
    Emitter<ScreenTimeState> emit,
  ) async {
    add(ScreenTimeSlotAssigned(event.slot, event.app));
  }

  Future<void> _onSlotAssigned(
    ScreenTimeSlotAssigned event,
    Emitter<ScreenTimeState> emit,
  ) async {
    final existingSlot = state.configForSlot(event.slot);
    final newConfig = ScreenTimeConfig(
      slot: event.slot,
      packageName: event.app.package,
      appName: event.app.label,
      openAppOnTap: existingSlot?.openAppOnTap ?? true,
    );

    final currentSlots = state.slots.where((c) => c.slot != event.slot).toList()
      ..add(newConfig)
      ..sort((a, b) => a.slot.compareTo(b.slot));

    await _repository.saveConfigs(currentSlots);

    final time = await _repository.getAppScreenTime(newConfig.packageName);
    final updatedTimes = Map<int, ({int millis, String formatted})>.from(state.slotTimes)
      ..[event.slot] = time;

    emit(state.copyWith(
      slots: currentSlots,
      slotTimes: updatedTimes,
    ));
  }

  Future<void> _onSlotRemoved(
    ScreenTimeSlotRemoved event,
    Emitter<ScreenTimeState> emit,
  ) async {
    final currentSlots = state.slots.where((c) => c.slot != event.slot).toList();
    await _repository.saveConfigs(currentSlots);

    final updatedTimes = Map<int, ({int millis, String formatted})>.from(state.slotTimes)
      ..remove(event.slot);

    emit(state.copyWith(
      slots: currentSlots,
      slotTimes: updatedTimes,
    ));
  }

  Future<void> _onOpenOnTapToggled(
    ScreenTimeOpenOnTapToggled event,
    Emitter<ScreenTimeState> emit,
  ) async {
    add(ScreenTimeSlotOpenOnTapToggled(event.slot, event.openAppOnTap));
  }

  Future<void> _onSlotOpenOnTapToggled(
    ScreenTimeSlotOpenOnTapToggled event,
    Emitter<ScreenTimeState> emit,
  ) async {
    final existing = state.configForSlot(event.slot);
    if (existing == null) return;
    final updated = existing.copyWith(openAppOnTap: event.openAppOnTap);

    final currentSlots = state.slots.where((c) => c.slot != event.slot).toList()
      ..add(updated)
      ..sort((a, b) => a.slot.compareTo(b.slot));

    await _repository.saveConfigs(currentSlots);
    emit(state.copyWith(slots: currentSlots));
  }

  Future<void> _onRefreshed(
    ScreenTimeRefreshed event,
    Emitter<ScreenTimeState> emit,
  ) async {
    final updatedTimes = <int, ({int millis, String formatted})>{};
    for (final slotConfig in state.slots) {
      if (slotConfig.packageName.isNotEmpty) {
        final time = await _repository.getAppScreenTime(slotConfig.packageName);
        updatedTimes[slotConfig.slot] = time;
      }
    }
    emit(state.copyWith(slotTimes: updatedTimes));
  }

  Future<void> _loadFullData(Emitter<ScreenTimeState> emit) async {
    final hasPerm = await _repository.hasUsageAccess();
    final configs = await _repository.loadConfigs();

    final times = <int, ({int millis, String formatted})>{};
    if (hasPerm) {
      for (final slot in configs) {
        if (slot.packageName.isNotEmpty) {
          final time = await _repository.getAppScreenTime(slot.packageName);
          times[slot.slot] = time;
        }
      }
    }

    final rawApps = await _repository.getLaunchableApps();
    final usageMap = hasPerm ? await _repository.getTodayUsageStats() : <String, int>{};

    final appItems = rawApps.map((a) {
      final millis = usageMap[a.package] ?? 0;
      return AppUsageItem(
        package: a.package,
        label: a.label,
        icon: a.icon,
        usageMillis: millis,
        formattedUsage: ScreenTimeRepository.formatMillis(millis),
      );
    }).toList();

    // Sort apps: apps with usage first (highest usage to lowest), then alphabetical
    appItems.sort((a, b) {
      if (a.usageMillis != b.usageMillis) {
        return b.usageMillis.compareTo(a.usageMillis);
      }
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });

    emit(state.copyWith(
      hasPermission: hasPerm,
      slots: configs,
      slotTimes: times,
      apps: appItems,
      isLoading: false,
    ));
  }
}
