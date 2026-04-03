class AuthUserAssignment {
  final String id;
  final String channelId;
  final String channelName;
  final String platformName;
  final String role;

  AuthUserAssignment({required this.id, required this.channelId, required this.channelName, required this.platformName, required this.role});

  factory AuthUserAssignment.fromJson(Map<String, dynamic> json) {
    return AuthUserAssignment(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      channelName: json['channel']['name'] as String,
      platformName: json['channel']['platform']['name'] as String,
      role: json['role'] as String,
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class AuthUser {
  final String id;
  final String email;
  final String role;
  final List<AuthUserAssignment> assignments;

  AuthUser({required this.id, required this.email, required this.role, required this.assignments});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => AuthUserAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? role,
    List<AuthUserAssignment>? assignments,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      assignments: assignments ?? this.assignments,
    );
  }
}
