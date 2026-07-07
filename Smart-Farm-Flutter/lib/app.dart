import 'package:flutter/material.dart';
import 'main.dart'; // عشان يشوف themeNotifier و languageNotifier
import 'constants.dart';

class PlantMonitorApp extends StatelessWidget {
  final Widget startScreen;

  const PlantMonitorApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    // بنستمع لتغيير اللغة
    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isArabic, child) {
        // وجواها بنستمع لتغيير الثيم
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, child) {
            return MaterialApp(
              title: 'FarmNet',
              debugShowCheckedModeBanner: false,
              themeMode: currentMode,
              
              // إعدادات الثيم (زي ما هي)
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                primarySwatch: Colors.green,
                scaffoldBackgroundColor: const Color(0xFFF6F7FB),
                colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accentColor),
                cardColor: Colors.white,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                primarySwatch: Colors.green,
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardColor: const Color(0xFF1E1E1E),
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.accentColor,
                  secondary: AppColors.accentColor,
                  surface: Color(0xFF1E1E1E),
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  iconTheme: IconThemeData(color: Colors.white),
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                textTheme: const TextTheme(
                  bodyMedium: TextStyle(color: Colors.white),
                  bodyLarge: TextStyle(color: Colors.white),
                ),
              ),

              // ✅ هنا السحر: تغيير اتجاه التطبيق بناءً على اللغة
              builder: (context, child) {
                return Directionality(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                );
              },

              home: startScreen,
            );
          },
        );
      },
    );
  }
}