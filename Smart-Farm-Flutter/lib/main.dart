import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'home_page.dart';
import 'screens/login_screen.dart';

// 1. متغيرات التحكم العالمية (Global Notifiers)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<bool> languageNotifier = ValueNotifier(false); // false = English, true = Arabic

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cqeqjiocahkpuclhgtzl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxZXFqaW9jYWhrcHVjbGhndHpsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDMyOTAxMywiZXhwIjoyMDc5OTA1MDEzfQ.-1gnfpnZYgSa0aQLtjqsc4JJ54SIFu4O5zLp65iP8GQ',
  );

  // 2. تحميل الإعدادات المحفوظة
  final prefs = await SharedPreferences.getInstance();
  
  // ثيم
  final bool isDark = prefs.getBool('is_dark') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  // لغة
  final bool isArabic = prefs.getBool('is_arabic') ?? false;
  languageNotifier.value = isArabic;

  // فحص الدخول
  final bool rememberMe = prefs.getBool('remember_me') ?? false;
  Widget firstScreen;

  if (!rememberMe) {
    await Supabase.instance.client.auth.signOut();
    firstScreen = const LoginScreen();
  } else {
    final session = Supabase.instance.client.auth.currentSession;
    firstScreen = session != null ? const HomePage() : const LoginScreen();
  }

  runApp(PlantMonitorApp(startScreen: firstScreen));
}