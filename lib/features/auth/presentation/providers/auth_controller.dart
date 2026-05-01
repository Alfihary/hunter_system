import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_auth_repository.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user_gender.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    return AuthState(user: _repository.currentUser);
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _repository.login(email: email, password: password);

      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserGender gender,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _repository.register(
        name: name,
        email: email,
        password: password,
        gender: gender,
      );

      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _repository.logout();
    state = const AuthState(user: null, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
