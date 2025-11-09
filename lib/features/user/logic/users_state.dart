import 'package:pharmacy/features/user/data/models/user_model.dart';

abstract class UsersState {}

class UsersInitial extends UsersState {}

class FetchUsersLoading extends UsersState {}

class FetchUsersSuccess extends UsersState {
  final List<UserModel> users;

  FetchUsersSuccess(this.users);
}

class FetchUsersError extends UsersState {
  final String error;

  FetchUsersError(this.error);
}

// Add/Edit User States
class AddUserLoading extends UsersState {}

class AddUserSuccess extends UsersState {}

class AddUserError extends UsersState {
  final String error;

  AddUserError(this.error);
}

class UpdateUserLoading extends UsersState {}

class UpdateUserSuccess extends UsersState {}

class UpdateUserError extends UsersState {
  final String error;

  UpdateUserError(this.error);
}


