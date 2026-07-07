import 'package:flutter/material.dart';

class AppColors {
  static const backgroundColor = Color(0xFFF6F7FB);

  static const cardColor = Colors.white;

  static const accentColor = Color(0xFF4CAF50);

  static const textColor = Color(0xFF333333);

  static const secondaryTextColor = Color(0xFF666666);

  static const successColor = Color(0xFF4CAF50);

  static const warningColor = Color(0xFFFF9800);
}

class AppConfig {
  /*
    ضع هنا:
    - IP جهاز السيرفر
    - أو رابط VPS
    - أو رابط Domain
  */

  // Local Network Example
  static const String serverBaseUrl = 'https://smartfarm.hassanmaher.tech';

  /*
    لو هتشغل على VPS:

    static const String serverBaseUrl =
        'https://api.smartfarm.com';
  */

  // Headers الخاصة بالـ Flask APIs
  static const Map<String, String> serverHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'FarmNet-App/1.0',
  };
}

// ===================================================
// ================= SENSORS LIST =====================
// ===================================================

// قائمة الحساسات
final List<Map<String, dynamic>> sensorsList = [
  {
    'name': 'SOIL MOISTURE',
    'icon': Icons.water_drop,
    'value_key': 'soil_moisture',
    'unit': '%',
    'color': const Color(0xFF4CAF50),
    'description': 'Soil Moisture percentage',
    'type': 'progress',
  },
  {
    'name': 'TEMPERATURE',
    'icon': Icons.thermostat,
    'value_key': 'temperature',
    'unit': '°C',
    'color': const Color(0xFFF44336),
    'description': 'Ambient temperature',
    'type': 'value',
  },
  {
    'name': 'HUMIDITY',
    'icon': Icons.air,
    'value_key': 'humidity',
    'unit': '%',
    'color': const Color(0xFF2196F3),
    'description': 'Air humidity level',
    'type': 'gauge',
  },
  {
    'name': 'LIGHT INTENSITY',
    'icon': Icons.light_mode,
    'value_key': 'light_intensity',
    'unit': '%',
    'color': const Color(0xFFFFEB3B),
    'description': 'Light Intensity percentage',
    'type': 'value',
  },
  {
    'name': 'AIR QUALITY',
    'icon': Icons.air,
    'value_key': 'air_quality',
    'unit': '%',
    'color': const Color(0xFFFF9800),
    'description': 'Air Quality Index',
    'type': 'value',
  },
  {
    'name': 'SOIL pH',
    'icon': Icons.science,
    'value_key': 'soil_ph',
    'unit': '',
    'color': const Color(0xFF009688),
    'description': 'Soil acidity level',
    'type': 'value',
  },
  {
    'name': 'SOIL EC',
    'icon': Icons.electrical_services,
    'value_key': 'soil_ec',
    'unit': 'mS/cm',
    'color': const Color(0xFF03A9F4),
    'description': 'Electrical Conductivity',
    'type': 'value',
  },
  {
    'name': 'WATER LEVEL',
    'icon': Icons.invert_colors,
    'value_key': 'water_level',
    'unit': '%',
    'color': const Color(0xFF2196F3),
    'description': 'Reservoir level',
    'type': 'progress',
  },
  {
    'name': 'UV INDEX',
    'icon': Icons.wb_sunny,
    'value_key': 'uv_index',
    'unit': '',
    'color': const Color(0xFFFF5722),
    'description': 'Sunlight intensity',
    'type': 'value',
  },
];
