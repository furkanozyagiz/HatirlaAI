import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/reminder.dart';
import 'services/database_service.dart';
import 'widgets/reminder_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Reminder> reminders = [];

  final TextEditingController controller = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    await DatabaseService.database;

    final data = await DatabaseService.getReminders();

    setState(() {
      reminders.clear();
      reminders.addAll(data);
    });
  }

  String getBurc(DateTime date) {
    int day = date.day;
    int month = date.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "♈ Koç";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "♉ Boğa";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20))
      return "♊ İkizler";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22))
      return "♋ Yengeç";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22))
      return "♌ Aslan";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22))
      return "♍ Başak";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22))
      return "♎ Terazi";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21))
      return "♏ Akrep";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21))
      return "♐ Yay";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19))
      return "♑ Oğlak";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "♒ Kova";

    return "♓ Balık";
  }

  void toggleReminder(int index) {
    setState(() {
      reminders[index].isCompleted = !reminders[index].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HatırlaAI"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Merhaba Furkan 👋",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              "Bugün ${DateFormat("dd MMMM yyyy", "tr_TR").format(DateTime.now())}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 5),

            Text(
              getBurc(DateTime.now()),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "📝 Bugünkü Hatırlatmalar",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  return ReminderCard(
                    reminder: reminders[index],
                    onTap: () {
                      toggleReminder(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
