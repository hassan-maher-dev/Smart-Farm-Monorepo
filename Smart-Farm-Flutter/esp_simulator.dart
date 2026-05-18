import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

// ===================================================
// ================= MAIN =============================
// ===================================================

void main() async {

  // ===================================================
  // ================= FLASK SERVER ====================
  // ===================================================

  const serverUrl =
      'http://192.168.1.5:5002';

  // ===================================================
  // ================= USER ID =========================
  // ===================================================

  const userId =
      '17b7dec9-b349-4a51-bf03-edb57fbf7793';

  final random = Random();

  // ===================================================
  // ================= DEVICES STATE ===================
  // ===================================================

  bool isPumpOn = false;

  bool isLightOn = false;

  // ===================================================
  // ================= SENSOR VALUES ===================
  // ===================================================

  double soilMoisture = 40.0;

  double lightIntensity = 100.0;

  print('🚀 Starting Flask ESP32 Simulator...');

  print(
    '⏳ Sending sensor data every 5 seconds...\n',
  );

  // ===================================================
  // ================= MAIN LOOP =======================
  // ===================================================

  Timer.periodic(
    const Duration(seconds: 5),
    (timer) async {

      // ================================================
      // ================ SENSOR SIMULATION =============
      // ================================================

      // محاكاة رطوبة التربة

      if (isPumpOn) {

        soilMoisture += 12.0;

      } else {

        soilMoisture -= 1.5;
      }

      soilMoisture =
          soilMoisture.clamp(0.0, 100.0);

      // محاكاة الضوء

      lightIntensity =
          random.nextDouble() > 0.2
          ? 100.0
          : 0.0;

      // باقي الحساسات

      double temperature =
          20.0 + random.nextDouble() * 15.0;

      double humidity =
          40.0 + random.nextDouble() * 30.0;

      double waterLevel =
          20.0 + random.nextDouble() * 80.0;

      double airQuality =
          10.0 + random.nextDouble() * 40.0;

      double soilPH =
          6.0 + random.nextDouble() * 1.6;

      double soilEC =
          1.0 + random.nextDouble() * 1.6;

      double uvIndex =
          (lightIntensity == 100.0)
          ? 5.0 + random.nextDouble() * 3.0
          : 0.0;

      // ================================================
      // ================= REQUEST DATA =================
      // ================================================

      final data = {

        'user_id': userId,

        'temperature':
            double.parse(
              temperature.toStringAsFixed(1),
            ),

        'humidity':
            double.parse(
              humidity.toStringAsFixed(1),
            ),

        'soil_moisture':
            double.parse(
              soilMoisture.toStringAsFixed(1),
            ),

        'light_intensity': lightIntensity,

        'water_level':
            double.parse(
              waterLevel.toStringAsFixed(1),
            ),

        'air_quality':
            double.parse(
              airQuality.toStringAsFixed(1),
            ),

        'soil_ph':
            double.parse(
              soilPH.toStringAsFixed(1),
            ),

        'soil_ec':
            double.parse(
              soilEC.toStringAsFixed(2),
            ),

        'uv_index':
            double.parse(
              uvIndex.toStringAsFixed(1),
            ),
      };

      // ================================================
      // ================= SEND REQUEST =================
      // ================================================

      try {

        final response = await http.post(

          Uri.parse('$serverUrl/api/data'),

          headers: {
            'Content-Type': 'application/json',
          },

          body: jsonEncode(data),
        );

        // ================================================
        // ================= SUCCESS ======================
        // ================================================

        if (response.statusCode == 201) {

          final responseData =
              jsonDecode(response.body);

          // ================================================
          // ================= READ COMMANDS ===============
          // ================================================

          isPumpOn =
              responseData['commands']
              ['water_pump'];

          isLightOn =
              responseData['commands']
              ['grow_lights'];

          final now = DateTime.now();

          final time =
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}:'
              '${now.second.toString().padLeft(2, '0')}';

          print(
            '✅ [$time] Sent Successfully',
          );

          print(
            '🌱 Soil Moisture: '
            '${data['soil_moisture']}%',
          );

          print(
            '🌡 Temperature: '
            '${data['temperature']}°C',
          );

          print(
            '💧 Humidity: '
            '${data['humidity']}%',
          );

          print(
            '🚰 Pump: '
            '${isPumpOn ? "ON" : "OFF"}',
          );

          print(
            '💡 Lights: '
            '${isLightOn ? "ON" : "OFF"}',
          );

          print(
            '-----------------------------------',
          );

        } else {

          print(
            '❌ Server Error: '
            '${response.statusCode}',
          );

          print(response.body);
        }

      } catch (e) {

        print('❌ Connection Error: $e');
      }
    },
  );
}