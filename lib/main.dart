import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Türkçe tarih formatlama verisini başlatıyoruz
  await initializeDateFormatting('tr_TR', null);

  // 2. Bildirim servisimizi başlatıyoruz
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HatırlaAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
