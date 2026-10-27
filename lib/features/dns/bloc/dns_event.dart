part of 'dns_bloc.dart';

sealed class DnsEvent extends Equatable {
  const DnsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the saved cycle and the live system state.
final class DnsStarted extends DnsEvent {
  const DnsStarted();
}

/// Re-reads the live setting (app resumed, or the tile changed it).
final class DnsLiveStateRefreshed extends DnsEvent {
  const DnsLiveStateRefreshed();
}

/// Adds or removes Off / Automatic from the cycle.
final class DnsFixedStateToggled extends DnsEvent {
  const DnsFixedStateToggled(this.mode);

  final PrivateDnsMode mode;

  @override
  List<Object?> get props => [mode];
}

final class DnsProviderToggled extends DnsEvent {
  const DnsProviderToggled(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class DnsProvidersReordered extends DnsEvent {
  const DnsProvidersReordered(this.oldIndex, this.newIndex);

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Adds a new provider, or replaces the one with the same id.
final class DnsProviderSaved extends DnsEvent {
  const DnsProviderSaved(this.provider);

  final DnsProvider provider;

  @override
  List<Object?> get props => [provider];
}

final class DnsProviderDeleted extends DnsEvent {
  const DnsProviderDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Undo for [DnsProviderDeleted].
final class DnsProviderRestored extends DnsEvent {
  const DnsProviderRestored(this.provider, this.index);

  final DnsProvider provider;
  final int index;

  @override
  List<Object?> get props => [provider, index];
}

/// Switches the system to [target] right now (needs WRITE_SECURE_SETTINGS).
final class DnsApplyRequested extends DnsEvent {
  const DnsApplyRequested(this.target);

  final PrivateDnsState target;

  @override
  List<Object?> get props => [target];
}
