import 'user_gender.dart';

/// Entidad de usuario de la aplicación.
///
/// ¿Qué hace?
/// Guarda los datos básicos del usuario autenticado.
///
/// ¿Para qué sirve?
/// Para personalizar la experiencia local de la app.
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserGender gender;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.gender = UserGender.unspecified,
  });

  String get welcomeTitle {
    switch (gender) {
      case UserGender.male:
        return 'Bienvenido, cazador';
      case UserGender.female:
        return 'Bienvenida, cazadora';
      case UserGender.unspecified:
        return 'Bienvenido/a, Hunter';
    }
  }
}
