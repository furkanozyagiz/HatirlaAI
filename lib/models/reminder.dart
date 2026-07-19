class Reminder {
  int? id;
  String title;
  DateTime dateTime;
  bool isCompleted;

  Reminder({
    this.id,
    required this.title,
    required this.dateTime,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      dateTime: DateTime.parse(map['dateTime']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
