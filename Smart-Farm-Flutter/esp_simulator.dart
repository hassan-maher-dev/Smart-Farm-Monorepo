import 'dart:async';
import 'dart:math';
import 'package:supabase/supabase.dart'; 

void main() async {
  // ============= 1. إعدادات Supabase =============
  const supabaseUrl = 'https://cqeqjiocahkpuclhgtzl.supabase.co/'; 
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxZXFqaW9jYWhrcHVjbGhndHpsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDMyOTAxMywiZXhwIjoyMDc5OTA1MDEzfQ.-1gnfpnZYgSa0aQLtjqsc4JJ54SIFu4O5zLp65iP8GQ'; 
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  // 🔑 كود الفلاح
  const userId = '17b7dec9-b349-4a51-bf03-edb57fbf7793'; 

  final random = Random();

  // متغيرات حالة الأجهزة (تلقائي / يدوي)
  String pumpMode = "auto";
  String lightMode = "auto";
  bool isPumpOn = false;
  bool isLightOn = false;

  // متغيرات الحساسات (قيم ابتدائية منطقية)
  double soilMoisture = 40.0;
  double lightIntensity = 100.0;

  print('🚀 Starting FarmNet ESP32 Simulator...');
  print('⏳ Running identical logic to C++ code (Sensors 5s, Status 2s). Press Ctrl+C to stop.\n');

  // ============= دالة تحديث حالة الأجهزة في Supabase =============
  Future<void> updateDeviceState(String deviceId, bool state) async {
    try {
      await supabase.from('devices')
          .update({'is_on': state})
          .eq('id', deviceId)
          .eq('user_id', userId);
      print('🔄 Supabase Updated: $deviceId is now ${state ? "ON" : "OFF"}');
    } catch (e) {
      print('❌ Error updating device state: $e');
    }
  }

  // ============= اللوب الأولى: قراءة حالة الأجهزة من السيرفر (كل 2 ثانية) =============
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    try {
      final response = await supabase.from('devices')
          .select('id, is_on, mode')
          .eq('user_id', userId);

      for (var item in response) {
        final id = item['id'];
        final isOn = item['is_on'] as bool;
        final mode = item['mode'] ?? 'auto';

        if (id == 'water_pump') {
          isPumpOn = isOn;
          pumpMode = mode;
        } else if (id == 'grow_lights') {
          isLightOn = isOn;
          lightMode = mode;
        }
      }
    } catch (e) {
      // نتجاهل الأخطاء الصامتة عشان الـ Terminal ميتزحمش
    }
  });

  // ============= اللوب الثانية: قراءة الحساسات، الأتمتة، والرفع (كل 5 ثواني) =============
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    
    // --- 1. محاكاة الحساسات (Read Sensors) ---
    
    // محاكاة رطوبة التربة (بتنشف لو الموتور مقفول، وبتزيد لو الموتور شغال)
    if (isPumpOn) {
      soilMoisture += 12.0; // الأرض بتشرب
    } else {
      soilMoisture -= 1.5;  // الأرض بتنشف
    }
    soilMoisture = soilMoisture.clamp(0.0, 100.0); // نضمن إنها بين 0 و 100

    // محاكاة الإضاءة (فرصة 20% إن الدنيا تضلم فجأة عشان اللمبات تشتغل)
    lightIntensity = random.nextDouble() > 0.2 ? 100.0 : 0.0;

    // باقي الحساسات محاكاة عشوائية حسب كود الـ ESP32
    double temperature = 20.0 + random.nextDouble() * 15.0;
    double humidity = 40.0 + random.nextDouble() * 30.0;
    double waterLevel = 20.0 + random.nextDouble() * 80.0;
    double airQuality = 10.0 + random.nextDouble() * 40.0;
    double soilPH = 6.0 + random.nextDouble() * 1.6;
    double soilEC = 1.0 + random.nextDouble() * 1.6;
    double uvIndex = (lightIntensity == 100.0) ? 5.0 + random.nextDouble() * 3.0 : 0.0;

    // --- 2. فحص الأتمتة (Check Automation) ---
    
    // أتمتة المضخة
    if (pumpMode == "auto") {
      if (soilMoisture < 30 && !isPumpOn) {
        isPumpOn = true;
        await updateDeviceState("water_pump", true);
        print('🤖 [AUTO] Soil dry (<30). Pump turned ON.');
      } else if (soilMoisture >= 60 && isPumpOn) {
        isPumpOn = false;
        await updateDeviceState("water_pump", false);
        print('🤖 [AUTO] Soil wet (>=60). Pump turned OFF.');
      }
    }

    // أتمتة اللمبات
    if (lightMode == "auto") {
      if (lightIntensity == 0 && !isLightOn) {
        isLightOn = true;
        await updateDeviceState("grow_lights", true);
        print('🤖 [AUTO] It is dark. Lights turned ON.');
      } else if (lightIntensity == 100 && isLightOn) {
        isLightOn = false;
        await updateDeviceState("grow_lights", false);
        print('🤖 [AUTO] It is bright. Lights turned OFF.');
      }
    }

    // --- 3. رفع البيانات (Upload Data to Supabase) ---
    final data = {
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
      await supabase.from('plant_data').insert(data);
      
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      print('✅ [$time] Sent -> Soil: ${data['soil_moisture']}% | Pump: $pumpMode (${isPumpOn ? "ON" : "OFF"}) | Light: $lightMode (${isLightOn ? "ON" : "OFF"})');
    } catch (e) {
      print('❌ Error sending data: $e');
    }
  });
}