class PipelineWeek {
  final String week;
  final String label;
  final int count;

  PipelineWeek({required this.week, required this.label, required this.count});

  factory PipelineWeek.fromJson(Map<String, dynamic> json) {
    return PipelineWeek(
      week: json['week'] as String,
      label: json['label'] as String,
      count: json['count'] as int,
    );
  }
}

class WorkloadChannel {
  final String channelId;
  final String handle;
  final String name;
  final int count;

  WorkloadChannel({required this.channelId, required this.handle, required this.name, required this.count});

  factory WorkloadChannel.fromJson(Map<String, dynamic> json) {
    return WorkloadChannel(
      channelId: json['channelId'] as String,
      handle: json['handle'] as String,
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }
}

class ContentMixItem {
  final String contentType;
  final int count;
  final double percent;

  ContentMixItem({required this.contentType, required this.count, required this.percent});

  factory ContentMixItem.fromJson(Map<String, dynamic> json) {
    return ContentMixItem(
      contentType: json['contentType'] as String,
      count: json['count'] as int,
      percent: (json['percent'] as num).toDouble(),
    );
  }
}

class HeatmapData {
  final Map<String, int> dateToCount;

  HeatmapData({required this.dateToCount});

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      dateToCount: json.map((key, value) => MapEntry(key, value as int)),
    );
  }
}

class LeadTimeWeek {
  final String week;
  final double avgDays;

  LeadTimeWeek({required this.week, required this.avgDays});

  factory LeadTimeWeek.fromJson(Map<String, dynamic> json) {
    return LeadTimeWeek(
      week: json['week'] as String,
      avgDays: (json['avgDays'] as num).toDouble(),
    );
  }
}

class TrendData {
  final String trend;
  final int current;
  final int previous;

  TrendData({required this.trend, required this.current, required this.previous});

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      trend: json['trend'] as String,
      current: json['current'] as int,
      previous: json['previous'] as int,
    );
  }
}
