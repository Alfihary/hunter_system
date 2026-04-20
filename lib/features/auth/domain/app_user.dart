/// Entidad de usuario de la aplicación.
///
/// En esta fase sólo guarda lo mínimo necesario para login local.
class AppUser {
  final String id;
  final String name;
  final String email;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
  });
}