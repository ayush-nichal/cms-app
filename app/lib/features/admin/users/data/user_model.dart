class AppUser {
  final String id;
  final String email;
  final String role;
  final String? whatsappNumber;
  final String? callmebotApiKey;
  final bool isActive;
  final List<UserAssignment> assignments;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.whatsappNumber,
    this.callmebotApiKey,
    required this.isActive,
    required this.assignments,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      whatsappNumber: json['whatsapp_number'] as String?,
      callmebotApiKey: json['callmebot_api_key'] as String?,
      isActive: json['is_active'] as bool,
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => UserAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  AppUser copyWith({
    String? email,
    String? role,
    String? whatsappNumber,
    String? callmebotApiKey,
    bool? isActive,
    List<UserAssignment>? assignments,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      role: role ?? this.role,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      callmebotApiKey: callmebotApiKey ?? this.callmebotApiKey,
      isActive: isActive ?? this.isActive,
      assignments: assignments ?? this.assignments,
    );
  }
}

class UserAssignment {
  final String id;
  final String channelId;
  final String channelName;
  final String platformName;

  UserAssignment({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.platformName,
  });

  factory UserAssignment.fromJson(Map<String, dynamic> json) {
    return UserAssignment(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      channelName: json['channel']['name'] as String,
      platformName: json['channel']['platform']['name'] as String,
    );
  }
}

class CreateUserRequest {
  final String email;
  final String password;
  final String? whatsappNumber;

  CreateUserRequest({
    required this.email,
    required this.password,
    this.whatsappNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (whatsappNumber != null && whatsappNumber!.isNotEmpty) 'whatsapp_number': whatsappNumber,
    };
  }
}

class UpdateUserRequest {
  final String? email;
  final String? password;
  final String? whatsappNumber;
  final String? callmebotApiKey;
  final bool? isActive;

  UpdateUserRequest({
    this.email,
    this.password,
    this.whatsappNumber,
    this.callmebotApiKey,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (password != null && password!.isNotEmpty) map['password'] = password;
    if (whatsappNumber != null) map['whatsapp_number'] = whatsappNumber;
    if (callmebotApiKey != null) map['callmebot_api_key'] = callmebotApiKey;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
