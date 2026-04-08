class Schedule {
  final String id;
  final String channelId;
  final String title;
  final String contentType; 
  final String? description;
  final String? mediaUrl;
  final DateTime scheduledAt;
  final String createdById;
  final String? creatorName;
  final String? channelName;
  final String? channelHandle;
  final String? platformName;
  final DateTime createdAt;

  Schedule({
    required this.id,
    required this.channelId,
    required this.title,
    required this.contentType,
    this.description,
    this.mediaUrl,
    required this.scheduledAt,
    required this.createdById,
    this.creatorName,
    this.channelName,
    this.channelHandle,
    this.platformName,
    required this.createdAt,
  });

  bool get isPastDue => scheduledAt.isBefore(DateTime.now());

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      title: json['title'] as String,
      contentType: json['content_type'] as String,
      description: json['description'] as String?,
      mediaUrl: json['media_url'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      createdById: json['created_by'] as String,
      creatorName: json['creator']?['email'] as String?,
      channelName: json['channel']?['name'] as String?,
      channelHandle: json['channel']?['handle'] as String?,
      platformName: json['channel']?['platform']?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class CreateScheduleRequest {
  final String channelId;
  final String title;
  final String contentType;
  final String? description;
  final String? mediaUrl;
  final DateTime scheduledAt;

  CreateScheduleRequest({
    required this.channelId,
    required this.title,
    required this.contentType,
    this.description,
    this.mediaUrl,
    required this.scheduledAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'title': title,
      'contentType': contentType,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (mediaUrl != null && mediaUrl!.isNotEmpty) 'mediaUrl': mediaUrl,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    };
  }
}

class SchedulePage {
  final List<Schedule> items;
  final int total;
  final int page;
  final bool hasMore;

  SchedulePage({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  factory SchedulePage.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List;
    final parsedItems = list.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
    final limit = 20; 
    final fetchedTotal = json['total'] as int;
    final pageNum = json['page'] as int;

    return SchedulePage(
      items: parsedItems,
      total: fetchedTotal,
      page: pageNum,
      hasMore: (pageNum * limit) < fetchedTotal,
    );
  }
}
