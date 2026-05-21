import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'home_page.dart';
import 'screens/login_screen.dart';

// متغيرات التحكم العالمية (Global Notifiers)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<bool> languageNotifier = ValueNotifier(false); // false = English, true = Arabic

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل الإعدادات المحفوظة
  final prefs = await SharedPreferences.getInstance();
  
  // ثيم
  final bool isDark = prefs.getBool('is_dark') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  // لغة
  final bool isArabic = prefs.getBool('is_arabic') ?? false;
  languageNotifier.value = isArabic;

  // فحص الدخول
  final bool rememberMe = prefs.getBool('remember_me') ?? false;
  final String? userId = prefs.getString('user_id'); // هنحفظ الـ userId وقت اللوجين

  Widget firstScreen;

  if (!rememberMe || userId == null || userId.isEmpty) {
    firstScreen = const LoginScreen();
  } else {
    firstScreen = const HomePage();
  }

  runApp(PlantMonitorApp(startScreen: firstScreen));
}