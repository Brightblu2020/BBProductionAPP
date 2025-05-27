import 'package:bb_factory_test_app/firebase_options.dart';
import 'package:bb_factory_test_app/hive/hive.dart';
import 'package:bb_factory_test_app/home.dart';
import 'package:bb_factory_test_app/utils/hive.dart';
import 'package:bb_factory_test_app/wifi_credential_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Storage().init();
  await HiveBox().init();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedSsid = prefs.getString(wifiSsidKey);
  final bool hasCredentials = savedSsid != null && savedSsid.isNotEmpty;

  runApp(MyApp(hasCredentials: hasCredentials));
}

class MyApp extends StatelessWidget {
  final bool hasCredentials;

  const MyApp({super.key, required this.hasCredentials});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BB Factory Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: hasCredentials ? const HomePage() : const WifiCredentialScreen(),
      getPages: [
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(
            name: '/wifi_credentials',
            page: () => const WifiCredentialScreen()),
      ],
    );
  }
}
