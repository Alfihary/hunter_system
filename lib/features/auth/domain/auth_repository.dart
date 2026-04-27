import 'app_user.dart';

/// Contrato de autenticación.
///
/// ¿Qué hace?
/// Define las operaciones disponibles para autenticar usuarios.
///
/// ¿Para qué sirve?
/// Para que la UI y los controllers no dependan directamente
/// de una implementación concreta como LocalAuthRepository.
abstract class AuthRepository {
  AppUser? get currentUser;

  Future<AppUser> login({
    required String email,
    required String password,
  });

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  /// Cambia la contraseña del usuario autenticado.
  ///
  /// Edge cases:
  /// - No hay sesión activa.
  /// - La contraseña actual no coincide.
  /// - La nueva contraseña es débil.
  /// - La nueva contraseña es igual a la actual.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();
}