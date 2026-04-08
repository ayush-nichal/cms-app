class Platform {
  final String id;
  final String name;
  final int channelCount;

  Platform({
    required this.id,
    required this.name,
    required this.channelCount,
  });

  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(
      id: json['id'] as String,
      name: json['name'] as String,
      channelCount: json['_count'] != null ? (json['_count']['channels'] as int? ?? 0) : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Platform copyWith({
    String? id,
    String? name,
    int? channelCount,
  }) {
    return Platform(
      id: id ?? this.id,
      name: name ?? this.name,
      channelCount: channelCount ?? this.channelCount,
    );
  }
}

class Channel {
  final String id;
  final String platformId;
  final String name;
  final String handle;
  final DateTime? lastPostAt;
  final int userCount;

  Channel({
    required this.id,
    required this.platformId,
    required this.name,
    required this.handle,
    this.lastPostAt,
    required this.userCount,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    DateTime? lastPost;
    if (json['schedules'] != null && (json['schedules'] as List).isNotEmpty) {
      lastPost = DateTime.parse(json['schedules'][0]['scheduled_at'] as String).toLocal();
    }

    final int users = json['_count'] != null ? (json['_count']['assignments'] as int? ?? 0) : 0;
    
    return Channel(
      id: json['id'] as String,
      platformId: json['platform_id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
      lastPostAt: lastPost,
      userCount: users,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform_id': platformId,
      'name': name,
      'handle': handle,
    };
  }

  Channel copyWith({
    String? id,
    String? platformId,
    String? name,
    String? handle,
    DateTime? lastPostAt,
    int? userCount,
  }) {
    return Channel(
      id: id ?? this.id,
      platformId: platformId ?? this.platformId,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      userCount: userCount ?? this.userCount,
    );
  }
}
