import '../../../core/exceptions/auth_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Repositorio local falso de autenticación.
///
/// Objetivo:
/// - Enseñar flujo de auth sin backend.
/// - Permitir register/login/logout.
/// - Mantener sesión sólo en memoria mientras la app está abierta.
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

    if (_registeredUser != null &&
        _registeredUser!.email.toLowerCase() == email.toLowerCase()) {
      throw AuthException('Ya existe una cuenta con ese correo.');
    }

    final user = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim(),
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

    if (_registeredUser == null || _registeredPassword == null) {
      throw AuthException('Primero debes registrar una cuenta.');
    }

    final emailMatches =
        _registeredUser!.email.toLowerCase() == email.trim().toLowerCase();
    final passwordMatches = _registeredPassword == password;

    if (!emailMatches || !passwordMatches) {
      throw AuthException('Correo o contraseña incorrectos.');
    }

    _sessionUser = _registeredUser;
    return _sessionUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 250));
    _sessionUser = null;
  }
}