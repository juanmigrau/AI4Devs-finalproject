part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.user,
    required this.statsLoading,
    this.stats,
    this.displayNameUpdated = false,
  });

  final UserProfile user;
  final PlayerStats? stats;
  final bool statsLoading;
  final bool displayNameUpdated;

  @override
  List<Object?> get props => [user, stats, statsLoading, displayNameUpdated];
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
