import '../../../core/exceptions/auth_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Repositorio local falso de autenticación.
///
/// Objetivo:
/// - Enseñar flujo de auth sin backend.
/// - Permitir register/login/logout.
/// - Permitir cambio de contraseña en memoria.
///
/// Limitaciones de esta fase:
/// - No persiste datos al cerrar la app.
/// - No cifra contraseñas.
/// - No usa red.
/// - No sirve para producción.
class LocalAuthRepository implements AuthRepository {
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.length < 2) {
      throw AuthException('El nombre debe tener al menos 2 caracteres.');
    }

    if (!_isValidEmail(cleanEmail)) {
      throw AuthException('Ingresa un correo válido.');
    }

    _validatePasswordStrength(password);

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

    return user;
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final cleanEmail = email.trim().toLowerCase();

    if (_registeredUser == null || _registeredPassword == null) {
      throw AuthException('Primero debes registrar una cuenta.');
    }

    final emailMatches = _registeredUser!.email.toLowerCase() == cleanEmail;
    final passwordMatches = _registeredPassword == password;

    if (!emailMatches || !passwordMatches) {
      throw AuthException('Correo o contraseña incorrectos.');
    }

    _sessionUser = _registeredUser;
    return _sessionUser!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_sessionUser == null) {
      throw AuthException('Debes iniciar sesión para cambiar tu contraseña.');
    }

    if (_registeredPassword == null) {
      throw AuthException('No hay contraseña registrada.');
    }

    if (_registeredPassword != currentPassword) {
      throw AuthException('La contraseña actual no es correcta.');
    }

    if (currentPassword == newPassword) {
      throw AuthException('La nueva contraseña debe ser diferente.');
    }

    _validatePasswordStrength(newPassword);

    _registeredPassword = newPassword;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 250));
    _sessionUser = null;
  }

  /// Valida formato básico de correo.
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  /// Valida fuerza mínima de contraseña.
  ///
  /// Regla simple para esta fase:
  /// - mínimo 8 caracteres
  /// - al menos una letra
  /// - al menos un número
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