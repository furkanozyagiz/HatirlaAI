import '../models/reminder.dart';

class ReminderService {
  final List<Reminder> _reminders = [];

  List<Reminder> get reminders => _reminders;

  void addReminder(Reminder reminder) {
    _reminders.add(reminder);
  }

  void removeReminder(Reminder reminder) {
    _reminders.remove(reminder);
  }

  void toggleReminder(Reminder reminder) {
    reminder.isCompleted = !reminder.isCompleted;
  }
}
