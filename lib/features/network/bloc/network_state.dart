part of 'network_bloc.dart';

final class NetworkState extends Equatable {
  const NetworkState({
    this.status,
    this.failures = 0,
  });

  /// Null until read, or when not running on Android.
  final NetworkStatus? status;

  /// Incremented on each refused change, so the UI can react once per failure.
  final int failures;

  NetworkState copyWith({
    NetworkStatus? status,
    int? failures,
  }) {
    return NetworkState(
      status: status ?? this.status,
      failures: failures ?? this.failures,
    );
  }

  @override
  List<Object?> get props => [status, failures];
}
