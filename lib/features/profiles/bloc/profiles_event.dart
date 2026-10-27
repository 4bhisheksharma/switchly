part of 'profiles_bloc.dart';

sealed class ProfilesEvent extends Equatable {
  const ProfilesEvent();

  @override
  List<Object?> get props => [];
}

final class ProfilesStarted extends ProfilesEvent {
  const ProfilesStarted();
}

/// Re-reads which profile is active (the tile may have changed it).
final class ProfilesRefreshed extends ProfilesEvent {
  const ProfilesRefreshed();
}

/// Adds a new profile, or replaces the one with the same id.
final class ProfileSaved extends ProfilesEvent {
  const ProfileSaved(this.profile);

  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

final class ProfileDeleted extends ProfilesEvent {
  const ProfileDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ProfileApplied extends ProfilesEvent {
  const ProfileApplied(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Puts back the settings from before the first profile was applied.
final class ProfileRestoreRequested extends ProfilesEvent {
  const ProfileRestoreRequested();
}
