import 'app_user.dart';

/// Contrato de autenticación.
///
/// La UI nunca debe depender directamente de una implementación concreta.
/// Habla contra esta interfaz.
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

  Future<void> logout();
}