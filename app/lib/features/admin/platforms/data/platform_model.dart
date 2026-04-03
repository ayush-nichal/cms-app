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

  Channel({
    required this.id,
    required this.platformId,
    required this.name,
    required this.handle,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      platformId: json['platform_id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
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
  }) {
    return Channel(
      id: id ?? this.id,
      platformId: platformId ?? this.platformId,
      name: name ?? this.name,
      handle: handle ?? this.handle,
    );
  }
}
