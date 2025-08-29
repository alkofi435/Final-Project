import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:htr/models/conversion_item.dart';
import 'package:htr/screens/home.dart';
import 'package:htr/screens/splash.dart';
import 'package:htr/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.initialize();

  // Hive configuration
  await Hive.initFlutter();
  Hive.registerAdapter(ConversionItemAdapter());
  await Hive.openBox<ConversionItem>('conversions');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstLaunch') ?? true;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: isFirstLaunch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final isFirstTime = snapshot.data!;
          return isFirstTime ? const SplashScreen() : const HomeScreen();
        },
      ),
    );
  }
}
