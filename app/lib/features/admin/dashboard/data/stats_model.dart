class PlatformStat {
  final String platformId;
  final String platformName;
  final int total;
  final int scheduled;
  final int posted;
  final int notPosted;

  PlatformStat({
    required this.platformId,
    required this.platformName,
    required this.total,
    required this.scheduled,
    required this.posted,
    required this.notPosted,
  });

  factory PlatformStat.fromJson(Map<String, dynamic> json) {
    return PlatformStat(
      platformId: json['platformId'] as String,
      platformName: json['platformName'] as String,
      total: json['total'] as int,
      scheduled: json['scheduled'] as int,
      posted: json['posted'] as int,
      notPosted: json['not_posted'] as int,
    );
  }
}

class ChannelStat {
  final String channelId;
  final String channelName;
  final String handle;
  final int total;
  final int scheduled;
  final int posted;
  final int notPosted;

  ChannelStat({
    required this.channelId,
    required this.channelName,
    required this.handle,
    required this.total,
    required this.scheduled,
    required this.posted,
    required this.notPosted,
  });

  factory ChannelStat.fromJson(Map<String, dynamic> json) {
    return ChannelStat(
      channelId: json['channelId'] as String,
      channelName: json['channelName'] as String,
      handle: json['handle'] as String? ?? '',
      total: json['total'] as int,
      scheduled: json['scheduled'] as int,
      posted: json['posted'] as int,
      notPosted: json['not_posted'] as int,
    );
  }
}

class OverviewStats {
  final List<PlatformStat> platforms;
  final int totalAcrossAll;

  OverviewStats({
    required this.platforms,
    required this.totalAcrossAll,
  });

  factory OverviewStats.fromJson(List<dynamic> jsonList) {
    final platforms = jsonList.map((e) => PlatformStat.fromJson(e as Map<String, dynamic>)).toList();
    final total = platforms.fold<int>(0, (sum, p) => sum + p.total);
    return OverviewStats(platforms: platforms, totalAcrossAll: total);
  }
}
