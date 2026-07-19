import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_card.dart';
// Yeni premium bileşeni import ettik
import '../widgets/time_picker_3d.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Reminder> reminders = [];
  final TextEditingController controller = TextEditingController();

  final String userName = "Furkan";

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> initDatabase() async {
    await DatabaseService.database;
    await refreshReminders();
  }

  Future<void> refreshReminders() async {
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

  // ========================================================
  // YENİ GÖREV EKLEME MODALI (PREMIUM ENTEGRASYONLU)
  // ========================================================
  void showAddTaskDialog() {
    DateTime selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              backgroundColor: Colors.white,
              title: const Row(
                children: [
                  Icon(
                    Icons.add_task_rounded,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Yeni Görev",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Görev Adı",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Örneğin: Market alışverişi",
                      prefixIcon: const Icon(Icons.edit_note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PREMIUM WIDGET BURAYA GELDİ
                  TimePicker3D(
                    initialDateTime: selectedDateTime,
                    onDateTimeChanged: (newDate) {
                      setDialogState(() {
                        selectedDateTime = newDate;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    controller.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) return;

                    // Geçmiş kontrolü
                    if (selectedDateTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Geçmiş bir zamana hatırlatıcı ekleyemezsiniz!",
                          ),
                        ),
                      );
                      return;
                    }

                    final reminder = Reminder(
                      title: controller.text.trim(),
                      dateTime: selectedDateTime,
                    );

                    try {
                      final insertedId = await DatabaseService.insertReminder(
                        reminder,
                      );
                      await NotificationService.scheduleNotification(
                        id: insertedId,
                        title: "HatırlaAI",
                        body: reminder.title,
                        scheduledTime: selectedDateTime,
                      );

                      await refreshReminders();
                      controller.clear();
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      debugPrint("KAYDETME HATASI: $e");
                    }
                  },
                  child: const Text("Ekle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void toggleReminder(int index) async {
    final reminder = reminders[index];
    reminder.isCompleted = !reminder.isCompleted;
    await DatabaseService.updateReminder(reminder);
    if (reminder.isCompleted && reminder.id != null) {
      await NotificationService.cancelNotification(reminder.id!);
    }
    await refreshReminders();
  }

  void deleteReminder(int index) async {
    final removedItem = reminders[index];
    if (removedItem.id != null) {
      await DatabaseService.deleteReminder(removedItem.id!);
      await NotificationService.cancelNotification(removedItem.id!);
    }
    await refreshReminders();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime simdi = DateTime.now();
    final String bugununTarihi = DateFormat(
      'dd MMMM yyyy, EEEE',
      'tr_TR',
    ).format(simdi);
    final String bugununBurcu = getBurc(simdi);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(title: const Text("HatırlaAI"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Kartı
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Merhaba $userName",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bugununTarihi,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            "Bugünkü Burcun: $bugununBurcu",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Hatırlatıcılarım",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: reminders.isEmpty
                  ? const Center(
                      child: Text("Henüz bir hatırlatıcı eklenmedi."),
                    )
                  : ListView.builder(
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        final item = reminders[index];
                        return Dismissible(
                          key: Key(item.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) => deleteReminder(index),
                          child: ReminderCard(
                            reminder: item,
                            onTap: () => toggleReminder(index),
                          ),
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
