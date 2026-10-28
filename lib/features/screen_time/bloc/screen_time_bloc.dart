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
  const ScreenTimeAppSelected(this.app);

  final AppUsageItem app;

  @override
  List<Object?> get props => [app.package];
}

class ScreenTimeOpenOnTapToggled extends ScreenTimeEvent {
  const ScreenTimeOpenOnTapToggled(this.openAppOnTap);

  final bool openAppOnTap;

  @override
  List<Object?> get props => [openAppOnTap];
}

class ScreenTimeRefreshed extends ScreenTimeEvent {
  const ScreenTimeRefreshed();
}

class ScreenTimeState extends Equatable {
  const ScreenTimeState({
    this.hasPermission = false,
    this.config,
    this.currentAppMillis = 0,
    this.currentAppFormatted = '0m',
    this.apps = const [],
    this.isLoading = false,
  });

  final bool hasPermission;
  final ScreenTimeConfig? config;
  final int currentAppMillis;
  final String currentAppFormatted;
  final List<AppUsageItem> apps;
  final bool isLoading;

  ScreenTimeState copyWith({
    bool? hasPermission,
    ScreenTimeConfig? config,
    int? currentAppMillis,
    String? currentAppFormatted,
    List<AppUsageItem>? apps,
    bool? isLoading,
  }) {
    return ScreenTimeState(
      hasPermission: hasPermission ?? this.hasPermission,
      config: config ?? this.config,
      currentAppMillis: currentAppMillis ?? this.currentAppMillis,
      currentAppFormatted: currentAppFormatted ?? this.currentAppFormatted,
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        hasPermission,
        config,
        currentAppMillis,
        currentAppFormatted,
        apps,
        isLoading,
      ];
}

class ScreenTimeBloc extends Bloc<ScreenTimeEvent, ScreenTimeState> {
  ScreenTimeBloc(this._repository) : super(const ScreenTimeState()) {
    on<ScreenTimeStarted>(_onStarted);
    on<ScreenTimePermissionCheckRequested>(_onPermissionCheck);
    on<ScreenTimeAppSelected>(_onAppSelected);
    on<ScreenTimeOpenOnTapToggled>(_onOpenOnTapToggled);
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
    final newConfig = ScreenTimeConfig(
      packageName: event.app.package,
      appName: event.app.label,
      openAppOnTap: state.config?.openAppOnTap ?? true,
    );
    await _repository.saveConfig(newConfig);

    final time = await _repository.getAppScreenTime(newConfig.packageName);
    emit(state.copyWith(
      config: newConfig,
      currentAppMillis: time.millis,
      currentAppFormatted: time.formatted,
    ));
  }

  Future<void> _onOpenOnTapToggled(
    ScreenTimeOpenOnTapToggled event,
    Emitter<ScreenTimeState> emit,
  ) async {
    if (state.config == null) return;
    final newConfig = state.config!.copyWith(openAppOnTap: event.openAppOnTap);
    await _repository.saveConfig(newConfig);
    emit(state.copyWith(config: newConfig));
  }

  Future<void> _onRefreshed(
    ScreenTimeRefreshed event,
    Emitter<ScreenTimeState> emit,
  ) async {
    if (state.config == null) return;
    final time = await _repository.getAppScreenTime(state.config!.packageName);
    emit(state.copyWith(
      currentAppMillis: time.millis,
      currentAppFormatted: time.formatted,
    ));
  }

  Future<void> _loadFullData(Emitter<ScreenTimeState> emit) async {
    final hasPerm = await _repository.hasUsageAccess();
    final config = await _repository.loadConfig();

    int currentMillis = 0;
    String currentFormatted = '0m';

    if (config != null && hasPerm) {
      final time = await _repository.getAppScreenTime(config.packageName);
      currentMillis = time.millis;
      currentFormatted = time.formatted;
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
      config: config,
      currentAppMillis: currentMillis,
      currentAppFormatted: currentFormatted,
      apps: appItems,
      isLoading: false,
    ));
  }
}
