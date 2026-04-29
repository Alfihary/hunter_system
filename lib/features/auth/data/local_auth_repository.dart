import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/exceptions/auth_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Repositorio local de autenticación persistente.
///
/// ¿Qué hace?
/// Permite:
/// - registrar una cuenta local
/// - iniciar sesión después de cerrar la app
/// - cerrar sesión
/// - cambiar contraseña
///
/// ¿Para qué sirve?
/// Para que la app funcione sin backend durante esta fase,
/// pero sin perder la cuenta al reiniciar la aplicación.
///
/// Nota de seguridad:
/// Esta implementación es educativa. Guarda contraseña local en texto plano.
/// En producción se debe usar backend, hashing seguro y almacenamiento protegido.
class LocalAuthRepository implements AuthRepository {
  static const String _userIdKey = 'auth_user_id';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userPasswordKey = 'auth_user_password';
  static const String _sessionActiveKey = 'auth_session_active';

  AppUser? _registeredUser;
  String? _registeredPassword;
  AppUser? _sessionUser;

  @override
  AppUser? get currentUser => _sessionUser;

  /// Registra una cuenta local y la guarda en el dispositivo.
  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
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
    );

    _registeredUser = user;
    _registeredPassword = password;
    _sessionUser = user;

    await _saveAccount(user: user, password: password, sessionActive: true);

    return user;
  }

  /// Inicia sesión usando la cuenta guardada localmente.
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

  /// Cambia la contraseña de la cuenta local.
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

  /// Cierra la sesión actual sin borrar la cuenta registrada.
  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 250));

    _sessionUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionActiveKey, false);
  }

  /// Carga la cuenta guardada en SharedPreferences.
  Future<void> _loadStoredAccount() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString(_userIdKey);
    final name = prefs.getString(_userNameKey);
    final email = prefs.getString(_userEmailKey);
    final password = prefs.getString(_userPasswordKey);
    final sessionActive = prefs.getBool(_sessionActiveKey) ?? false;

    if (id == null || name == null || email == null || password == null) {
      _registeredUser = null;
      _registeredPassword = null;
      _sessionUser = null;
      return;
    }

    final user = AppUser(id: id, name: name, email: email);

    _registeredUser = user;
    _registeredPassword = password;
    _sessionUser = sessionActive ? user : null;
  }

  /// Guarda la cuenta localmente.
  Future<void> _saveAccount({
    required AppUser user,
    required String password,
    required bool sessionActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userEmailKey, user.email);
    await prefs.setString(_userPasswordKey, password);
    await prefs.setBool(_sessionActiveKey, sessionActive);
  }

  /// Valida formato básico de correo.
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  /// Valida fuerza mínima de contraseña.
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
