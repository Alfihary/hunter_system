/// Género seleccionado por el usuario.
///
/// ¿Para qué sirve?
/// Para personalizar textos como:
/// - Bienvenido, cazador
/// - Bienvenida, cazadora
/// - Bienvenido/a, Hunter
enum UserGender {
  male,
  female,
  unspecified;

  String get label {
    switch (this) {
      case UserGender.male:
        return 'Masculino';
      case UserGender.female:
        return 'Femenino';
      case UserGender.unspecified:
        return 'Prefiero no decir';
    }
  }

  String get storageValue {
    switch (this) {
      case UserGender.male:
        return 'male';
      case UserGender.female:
        return 'female';
      case UserGender.unspecified:
        return 'unspecified';
    }
  }

  static UserGender fromStorage(String? value) {
    switch (value) {
      case 'male':
        return UserGender.male;
      case 'female':
        return UserGender.female;
      default:
        return UserGender.unspecified;
    }
  }
}
