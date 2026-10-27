part of 'setup_bloc.dart';

sealed class SetupEvent extends Equatable {
  const SetupEvent();

  @override
  List<Object?> get props => [];
}

/// Loads device info and the initial permission state.
final class SetupStarted extends SetupEvent {
  const SetupStarted();
}

/// Re-checks the permission ("Check again", or the app returning to the foreground).
final class SetupPermissionCheckRequested extends SetupEvent {
  const SetupPermissionCheckRequested();
}
