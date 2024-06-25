class TimeEntry {
  final int? id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  TimeEntry({
    this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration': duration.inMinutes,
    };
  }
}
