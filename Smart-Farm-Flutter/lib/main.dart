import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'home_page.dart';
import 'screens/login_screen.dart';

// 1. متغيرات التحكم العالمية (Global Notifiers)
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.light);

final ValueNotifier<bool> languageNotifier =
    ValueNotifier(false); // false = English, true = Arabic

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // ================= تحميل الإعدادات =================

  final prefs = await SharedPreferences.getInstance();

  // ================= الثيم =================

  final bool isDark =
      prefs.getBool('is_dark') ?? false;

  themeNotifier.value =
      isDark ? ThemeMode.dark : ThemeMode.light;

  // ================= اللغة =================

  final bool isArabic =
      prefs.getBool('is_arabic') ?? false;

  languageNotifier.value = isArabic;

  // ================= فحص تسجيل الدخول =================

  final bool rememberMe =
      prefs.getBool('remember_me') ?? false;

  Widget firstScreen;

  /*
    بما إننا شيلنا Supabase بالكامل،
    هنعتبر إن وجود remember_me = true
    معناه إن المستخدم مسجل دخول.
  */

  if (rememberMe) {

    firstScreen = const HomePage();

  } else {

    firstScreen = const LoginScreen();
  }

  // ================= تشغيل التطبيق =================

  runApp(
    PlantMonitorApp(
      startScreen: firstScreen,
    ),
  );
}