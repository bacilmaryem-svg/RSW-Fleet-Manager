class UserSession {
  final String username;
  final String role;
  final DateTime loginTime;

  UserSession({
    required this.username,
    required this.role,
    required this.loginTime,
  });
}
