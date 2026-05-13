import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../data/models/profile_model.dart';
import '../../../domain/usecases/manage_profile.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadActiveProfile extends ProfileEvent {}

class CreateProfile extends ProfileEvent {
  final String name;
  final Color themeColor;
  final int avatarIndex;
  CreateProfile(
      {required this.name, required this.themeColor, this.avatarIndex = 0});
  @override
  List<Object?> get props => [name, themeColor.value, avatarIndex];
}

class UpdateProfileEvent extends ProfileEvent {
  final ProfileModel profile;
  UpdateProfileEvent(this.profile);
  @override
  List<Object?> get props => [profile];
}

class SwitchProfile extends ProfileEvent {
  final String profileId;
  SwitchProfile(this.profileId);
  @override
  List<Object?> get props => [profileId];
}

class DeleteProfile extends ProfileEvent {
  final String profileId;
  DeleteProfile(this.profileId);
  @override
  List<Object?> get props => [profileId];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;
  ProfileLoaded(this.profile);
  @override
  List<Object?> get props =>
      [profile.id, profile.name, profile.themeColorValue];
}

class ProfileNotFound extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ManageProfile _manageProfile;

  ProfileBloc(this._manageProfile) : super(ProfileInitial()) {
    on<LoadActiveProfile>(_onLoad);
    on<CreateProfile>(_onCreate);
    on<UpdateProfileEvent>(_onUpdate);
    on<SwitchProfile>(_onSwitch);
    on<DeleteProfile>(_onDelete);
  }

  Future<void> _onLoad(
      LoadActiveProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final profile = _manageProfile.getActiveProfile();
    if (profile == null) {
      emit(ProfileNotFound());
    } else {
      emit(ProfileLoaded(profile));
    }
  }

  Future<void> _onCreate(
      CreateProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final profile = await _manageProfile.createProfile(
        name: event.name,
        themeColorValue: event.themeColor.value,
        avatarIndex: event.avatarIndex,
      );
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    await _manageProfile.updateProfile(event.profile);
    emit(ProfileLoaded(event.profile));
  }

  Future<void> _onSwitch(
      SwitchProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    await _manageProfile.switchProfile(event.profileId);
    final profile = _manageProfile.getActiveProfile();
    if (profile == null) {
      emit(ProfileNotFound());
    } else {
      emit(ProfileLoaded(profile));
    }
  }

  Future<void> _onDelete(
      DeleteProfile event, Emitter<ProfileState> emit) async {
    await _manageProfile.deleteProfile(event.profileId);
    final profile = _manageProfile.getActiveProfile();
    if (profile == null) {
      emit(ProfileNotFound());
    } else {
      emit(ProfileLoaded(profile));
    }
  }
}
