import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/dns_models.dart';
import '../data/dns_repository.dart';

part 'dns_event.dart';
part 'dns_state.dart';

/// Owns the Private DNS tile cycle and the live system setting.
///
/// Every config change is saved immediately, so the tile picks it up on its next tap.
class DnsBloc extends Bloc<DnsEvent, DnsState> {
  DnsBloc(this._repository) : super(const DnsState()) {
    on<DnsStarted>(_onStarted);
    on<DnsLiveStateRefreshed>(_onLiveStateRefreshed);
    on<DnsFixedStateToggled>(_onFixedStateToggled);
    on<DnsProviderToggled>(_onProviderToggled);
    on<DnsProvidersReordered>(_onProvidersReordered);
    on<DnsProviderSaved>(_onProviderSaved);
    on<DnsProviderDeleted>(_onProviderDeleted);
    on<DnsProviderRestored>(_onProviderRestored);
    on<DnsApplyRequested>(_onApplyRequested);
  }

  final DnsRepository _repository;

  Future<void> _onStarted(DnsStarted event, Emitter<DnsState> emit) async {
    final config = await _repository.loadConfig();
    final live = await _readLive();
    emit(state.copyWith(status: DnsStatus.ready, config: config, live: live));
  }

  Future<void> _onLiveStateRefreshed(DnsLiveStateRefreshed event, Emitter<DnsState> emit) async {
    final live = await _readLive();
    if (live != null) emit(state.copyWith(live: live));
  }

  Future<void> _onFixedStateToggled(DnsFixedStateToggled event, Emitter<DnsState> emit) async {
    final config = state.config;
    final enable = switch (event.mode) {
      PrivateDnsMode.off => !config.includeOff,
      PrivateDnsMode.automatic => !config.includeAutomatic,
      PrivateDnsMode.hostname => throw ArgumentError('Use DnsProviderToggled for providers'),
    };
    if (!enable && !config.canRemoveFromCycle) return;
    await _save(
      emit,
      event.mode == PrivateDnsMode.off ? config.copyWith(includeOff: enable) : config.copyWith(includeAutomatic: enable),
    );
  }

  Future<void> _onProviderToggled(DnsProviderToggled event, Emitter<DnsState> emit) async {
    final config = state.config;
    final providers = [
      for (final p in config.providers)
        if (p.id == event.id) p.copyWith(enabled: !p.enabled) else p,
    ];
    final disabling = config.providers.any((p) => p.id == event.id && p.enabled);
    if (disabling && !config.canRemoveFromCycle) return;
    await _save(emit, config.copyWith(providers: providers));
  }

  Future<void> _onProvidersReordered(DnsProvidersReordered event, Emitter<DnsState> emit) async {
    final providers = [...state.config.providers];
    // newIndex is already adjusted for the removal (onReorderItem semantics).
    providers.insert(event.newIndex, providers.removeAt(event.oldIndex));
    await _save(emit, state.config.copyWith(providers: providers));
  }

  Future<void> _onProviderSaved(DnsProviderSaved event, Emitter<DnsState> emit) async {
    final providers = [...state.config.providers];
    final index = providers.indexWhere((p) => p.id == event.provider.id);
    if (index == -1) {
      providers.add(event.provider);
    } else {
      providers[index] = event.provider;
    }
    await _save(emit, state.config.copyWith(providers: providers));
  }

  Future<void> _onProviderDeleted(DnsProviderDeleted event, Emitter<DnsState> emit) async {
    final config = state.config;
    final target = config.providers.where((p) => p.id == event.id).firstOrNull;
    if (target == null || (target.enabled && !config.canRemoveFromCycle)) return;
    await _save(emit, config.copyWith(providers: [...config.providers]..remove(target)));
  }

  Future<void> _onProviderRestored(DnsProviderRestored event, Emitter<DnsState> emit) async {
    final providers = [...state.config.providers];
    providers.insert(event.index.clamp(0, providers.length), event.provider);
    await _save(emit, state.config.copyWith(providers: providers));
  }

  Future<void> _onApplyRequested(DnsApplyRequested event, Emitter<DnsState> emit) async {
    emit(state.copyWith(applying: true));
    final ok = await _repository.apply(event.target);
    final live = await _readLive();
    emit(state.copyWith(
      applying: false,
      live: live,
      applyFailures: ok ? state.applyFailures : state.applyFailures + 1,
    ));
  }

  Future<void> _save(Emitter<DnsState> emit, DnsConfig config) async {
    emit(state.copyWith(config: config));
    await _repository.saveConfig(config);
  }

  Future<PrivateDnsState?> _readLive() async {
    try {
      return await _repository.readLiveState();
    } on Exception {
      return null; // Not on Android (tests, desktop preview).
    }
  }
}
