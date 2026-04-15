import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'database/database_helper.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const StallPOSApp());
}

class StallPOSApp extends StatelessWidget {
  const StallPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '摆摊进销存',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      home: const HomeScreen(),
    );
  }
}
