class WorkSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String project;

  WorkSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.project,
  });

  bool get isActive => endTime == null;

  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }
}
