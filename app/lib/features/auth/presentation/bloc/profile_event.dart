part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

final class ProfileDisplayNameSubmitted extends ProfileEvent {
  const ProfileDisplayNameSubmitted(this.displayName);

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}

final class DeleteAccountRequested extends ProfileEvent {
  const DeleteAccountRequested({this.password});

  final String? password;

  @override
  List<Object?> get props => [password];
}
