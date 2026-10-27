part of 'profiles_bloc.dart';

final class ProfilesState extends Equatable {
  const ProfilesState({
    this.loaded = false,
    this.profiles = const [],
    this.activeId,
    this.busy = false,
    this.failures = 0,
  });

  final bool loaded;
  final List<Profile> profiles;

  /// The applied profile, or null when none is.
  final String? activeId;
  final bool busy;

  /// Incremented each time a profile couldn't be fully applied.
  final int failures;

  Profile? get active => profiles.where((p) => p.id == activeId).firstOrNull;

  /// Note: can't clear [activeId]; the bloc builds a fresh state for that.
  ProfilesState copyWith({bool? loaded, List<Profile>? profiles, bool? busy, int? failures}) {
    return ProfilesState(
      loaded: loaded ?? this.loaded,
      profiles: profiles ?? this.profiles,
      activeId: activeId,
      busy: busy ?? this.busy,
      failures: failures ?? this.failures,
    );
  }

  @override
  List<Object?> get props => [loaded, profiles, activeId, busy, failures];
}
