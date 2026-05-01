import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/exceptions/auth_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/user_gender.dart';

class LocalAuthRepository implements AuthRepository {
  static const String _userIdKey = 'auth_user_id';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userGenderKey = 'auth_user_gender';
  static const String _userPasswordKey = 'auth_user_password';
  static const String _sessionActiveKey = 'auth_session_active';

  AppUser? _registeredUser;
  String? _registeredPassword;
  AppUser? _sessionUser;

  @override
  AppUser? get currentUser => _sessionUser;

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserGender gender,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.length < 2) {
      throw AuthException('El nombre debe tener al menos 2 caracteres.');
    }

    if (!_isValidEmail(cleanEmail)) {
      throw AuthException('Ingresa un correo válido.');
    }

    _validatePasswordStrength(password);

    await _loadStoredAccount();

    if (_registeredUser != null &&
        _registeredUser!.email.toLowerCase() == cleanEmail) {
      throw AuthException('Ya existe una cuenta con ese correo.');
    }

    final user = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      email: cleanEmail,
      gender: gender,
    );

    _registeredUser = user;
    _registeredPassword = password;
    _sessionUser = user;

    await _saveAccount(user: user, password: password, sessionActive: true);

    return user;
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final cleanEmail = email.trim().toLowerCase();

    await _loadStoredAccount();

    if (_registeredUser == null || _registeredPassword == null) {
      throw AuthException('Primero debes registrar una cuenta.');
    }

    final emailMatches = _registeredUser!.email.toLowerCase() == cleanEmail;
    final passwordMatches = _registeredPassword == password;

    if (!emailMatches || !passwordMatches) {
      throw AuthException('Correo o contraseña incorrectos.');
    }

    _sessionUser = _registeredUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionActiveKey, true);

    return _sessionUser!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    await _loadStoredAccount();

    if (_registeredUser == null || _registeredPassword == null) {
      throw AuthException('No hay cuenta registrada.');
    }

    if (_sessionUser == null) {
      throw AuthException('Debes iniciar sesión para cambiar tu contraseña.');
    }

    if (_registeredPassword != currentPassword) {
      throw AuthException('La contraseña actual no es correcta.');
    }

    if (currentPassword == newPassword) {
      throw AuthException('La nueva contraseña debe ser diferente.');
    }

    _validatePasswordStrength(newPassword);

    _registeredPassword = newPassword;

    await _saveAccount(
      user: _registeredUser!,
      password: newPassword,
      sessionActive: true,
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 250));

    _sessionUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionActiveKey, false);
  }

  Future<void> _loadStoredAccount() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString(_userIdKey);
    final name = prefs.getString(_userNameKey);
    final email = prefs.getString(_userEmailKey);
    final genderValue = prefs.getString(_userGenderKey);
    final password = prefs.getString(_userPasswordKey);
    final sessionActive = prefs.getBool(_sessionActiveKey) ?? false;

    if (id == null || name == null || email == null || password == null) {
      _registeredUser = null;
      _registeredPassword = null;
      _sessionUser = null;
      return;
    }

    final user = AppUser(
      id: id,
      name: name,
      email: email,
      gender: UserGender.fromStorage(genderValue),
    );

    _registeredUser = user;
    _registeredPassword = password;
    _sessionUser = sessionActive ? user : null;
  }

  Future<void> _saveAccount({
    required AppUser user,
    required String password,
    required bool sessionActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userEmailKey, user.email);
    await prefs.setString(_userGenderKey, user.gender.storageValue);
    await prefs.setString(_userPasswordKey, password);
    await prefs.setBool(_sessionActiveKey, sessionActive);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _validatePasswordStrength(String password) {
    final hasMinLength = password.length >= 8;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);

    if (!hasMinLength || !hasLetter || !hasNumber) {
      throw AuthException(
        'La contraseña debe tener mínimo 8 caracteres, una letra y un número.',
      );
    }
  }
}
