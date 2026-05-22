import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // 🔗 رابط سيرفر الـ AWS Ingress الخاص بك مباشرة (بدون بورت 5002 لأن الانجرس يستقبل على بورت 80)
  const String serverBaseUrl = 'http://a57f0c7a9303740ed945af4905efe5e8-1757069761.us-east-1.elb.amazonaws.com';
  
  // 🔑 كود الفلاح الثابت المبرمج في الباك إند (Mock User)
  const userId = '17b7dec9-b349-4a51-bf03-edb57fbf7793';
  final random = Random();

  String pumpMode = "auto";
  String lightMode = "auto";
  bool isPumpOn = false;
  bool isLightOn = false;

  double soilMoisture = 40.0;
  double lightIntensity = 100.0;

  print('🚀 Starting FarmNet ESP32 Simulator (AWS Backend)...');
  print('⏳ Running identical logic to C++ code. Press Ctrl+C to stop.\n');

  // دالة لتحديث حالة الأجهزة عن طريق الـ API
  Future<void> updateDeviceState(String deviceId, bool state) async {
    try {
      await http.post(
        Uri.parse('$serverBaseUrl/api/devices/control'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'device_id': deviceId,
          'is_on': state,
          'mode': 'auto' // لأن التغيير دا جي من الأتمتة الداخلية للمتحكم
        })
      );
      print('🔄 Server Updated: $deviceId is now ${state ? "ON" : "OFF"}');
    } catch (e) {
      print('❌ Error updating device state: $e');
    }
  }

  // اللوب الأولى: قراءة حالة الأجهزة من السيرفر (كل 2 ثانية) لكي يستجيب السيميوليتور لأزرار الويب
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    try {
      final response = await http.get(Uri.parse('$serverBaseUrl/api/devices/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('water_pump')) {
          isPumpOn = data['water_pump']['is_on'] ?? false;
          pumpMode = data['water_pump']['mode'] ?? 'auto';
        }
        if (data.containsKey('grow_lights')) {
          isLightOn = data['grow_lights']['is_on'] ?? false;
          lightMode = data['grow_lights']['mode'] ?? 'auto';
        }
      }
    } catch (e) {
       // نتجاهل الأخطاء الصامتة في الشبكة
    }
  });

  // اللوب الثانية: قراءة الحساسات، الأتمتة، والرفع (كل 5 ثواني)
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    
    // محاكاة الحساسات (تزيد الرطوبة إذا كانت المضخة تعمل، وتقل إذا توقفت)
    if (isPumpOn) {
      soilMoisture += 12.0; 
    } else {
      soilMoisture -= 1.5;  
    }
    soilMoisture = soilMoisture.clamp(0.0, 100.0);

    lightIntensity = random.nextDouble() > 0.2 ? 100.0 : 0.0;

    double temperature = 20.0 + random.nextDouble() * 15.0;
    double humidity = 40.0 + random.nextDouble() * 30.0;
    double waterLevel = 20.0 + random.nextDouble() * 80.0;
    double airQuality = 10.0 + random.nextDouble() * 40.0;
    double soilPH = 6.0 + random.nextDouble() * 1.6;
    double soilEC = 1.0 + random.nextDouble() * 1.6;
    double uvIndex = (lightIntensity == 100.0) ? 5.0 + random.nextDouble() * 3.0 : 0.0;

    // أتمتة المضخة (Local Automation Logic)
    if (pumpMode == "auto") {
      if (soilMoisture < 30 && !isPumpOn) {
        isPumpOn = true;
        print('🤖 [AUTO] Soil dry (<30). Pump turned ON.');
        await updateDeviceState('water_pump', true);
      } else if (soilMoisture >= 60 && isPumpOn) {
        isPumpOn = false;
        print('🤖 [AUTO] Soil wet (>=60). Pump turned OFF.');
        await updateDeviceState('water_pump', false);
      }
    }

    // أتمتة اللمبات
    if (lightMode == "auto") {
      if (lightIntensity == 0 && !isLightOn) {
        isLightOn = true;
        print('🤖 [AUTO] It is dark. Lights turned ON.');
        await updateDeviceState('grow_lights', true);
      } else if (lightIntensity == 100 && isLightOn) {
        isLightOn = false;
        print('🤖 [AUTO] It is bright. Lights turned OFF.');
        await updateDeviceState('grow_lights', false);
      }
    }

    // تجهيز حزمة البيانات الذاهبة للسيرفر
    final telemetryData = {
      'user_id': userId,
      'temperature': double.parse(temperature.toStringAsFixed(1)),
      'humidity': double.parse(humidity.toStringAsFixed(1)),
      'soil_moisture': double.parse(soilMoisture.toStringAsFixed(1)),
      'light_intensity': lightIntensity,
      'water_level': double.parse(waterLevel.toStringAsFixed(1)),
      'air_quality': double.parse(airQuality.toStringAsFixed(1)),
      'soil_ph': double.parse(soilPH.toStringAsFixed(1)),
      'soil_ec': double.parse(soilEC.toStringAsFixed(2)),
      'uv_index': double.parse(uvIndex.toStringAsFixed(1)),
    };

    try {
      final response = await http.post(
        Uri.parse('$serverBaseUrl/api/data'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(telemetryData)
      );
      
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      if(response.statusCode == 201) {
         print('✅ [$time] Sent Data -> Soil: ${telemetryData['soil_moisture']}% | Temp: ${telemetryData['temperature']}°C | Pump: ${isPumpOn ? "ON" : "OFF"}');
      } else {
         print('⚠️ [$time] Failed to sync. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending data: $e');
    }
  });
}