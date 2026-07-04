import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

// ==========================================
// ⚙️ إعدادات الاتصال بالسيرفر
// ==========================================
// ملاحظة: استخدم 127.0.0.1 إذا كنت تشغل المحاكي كـ Dart Script على الكمبيوتر
// وإذا كنت تشغله على جهاز آخر، ضع IP السيرفر (مثل 192.168.1.5)
const String baseUrl = 'https://smartfarm.hassanmaher.tech/api';
// ==========================================
// 🔐 بيانات اعتماد الهاردوير (Hardware Credentials)
// ==========================================
// يمكنك استخدام حسابك الذي سجلته في تطبيق الموبايل لترى القراءات هناك
const String deviceEmail = 'hassan@gmail.com';
const String devicePassword = '123456';

String? jwtToken;
final Random random = Random();

// ==========================================
// 🛡️ دالة المصادقة والحصول على التوكن
// ==========================================
Future<bool> authenticateHardware() async {
  print('⏳ جاري محاولة مصادقة جهاز ESP32 مع السيرفر...');

  try {
    // 1. محاولة تسجيل الدخول
    var loginResponse = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': deviceEmail,
        'password': devicePassword,
      }),
    );

    if (loginResponse.statusCode == 200) {
      var data = jsonDecode(loginResponse.body);
      jwtToken = data['token'];
      print('✅ تم تسجيل دخول الـ ESP32 بنجاح! (تم استلام JWT Token)');
      return true;
    } else if (loginResponse.statusCode == 401) {
      // 2. إذا فشل الدخول (الحساب غير موجود)، نقوم بإنشائه تلقائياً
      print('⚠️ الحساب غير موجود. جاري إنشاء حساب جديد للمزرعة تلقائياً...');
      var registerResponse = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': deviceEmail,
          'password': devicePassword,
          'farm_name': 'مزرعة المحاكي (ESP32 Simulator)'
        }),
      );

      if (registerResponse.statusCode == 201) {
        print('✅ تم إنشاء الحساب بنجاح! جاري تسجيل الدخول...');
        return await authenticateHardware(); // إعادة المحاولة بعد التسجيل
      } else {
        print('❌ فشل إنشاء الحساب: ${registerResponse.body}');
        return false;
      }
    } else {
      print('❌ خطأ غير متوقع: ${loginResponse.body}');
      return false;
    }
  } catch (e) {
    print(
        '❌ تعذر الاتصال بالسيرفر. يرجى التأكد من تشغيل الباك إند (Flask): $e');
    return false;
  }
}

// ==========================================
// 📡 توليد بيانات الحساسات العشوائية
// ==========================================
double randomDouble(double min, double max) {
  return double.parse(
      (min + random.nextDouble() * (max - min)).toStringAsFixed(2));
}

Map<String, dynamic> generateMockTelemetry() {
  return {
    'temperature': randomDouble(20.0, 35.0),
    'humidity': randomDouble(40.0, 70.0),
    'soil_moisture': randomDouble(30.0, 80.0),
    'light_intensity': randomDouble(800.0, 2000.0),
    'water_level': randomDouble(50.0, 100.0),
    'air_quality': randomDouble(85.0, 100.0),
    'soil_ph': randomDouble(6.0, 7.5),
    'soil_ec': randomDouble(1.0, 2.5),
    'uv_index': randomDouble(2.0, 8.0)
  };
}

// ==========================================
// 🚀 الدالة الرئيسية (نقطة انطلاق المحاكي)
// ==========================================
void main() async {
  print('================================================');
  print('🌱 Smart Farm ESP32 Simulator - Secure Edition 🔒');
  print('================================================\n');

  // خطوة 1: الحصول على تصريح المرور (JWT)
  bool isAuthenticated = await authenticateHardware();

  if (!isAuthenticated || jwtToken == null) {
    print('🚫 تم إيقاف المحاكي بسبب فشل المصادقة.');
    return;
  }

  print('\n📡 بدء بث قراءات الحساسات كل 5 ثوانٍ...\n');

  // خطوة 2: حلقة الإرسال الدورية (Polling)
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    final telemetryData = generateMockTelemetry();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken', // 🔑 إرفاق التوكن هنا!
        },
        body: jsonEncode(telemetryData),
      );

      if (response.statusCode == 201) {
        print(
            '📤 [نجاح] تم إرسال القراءات: درجة الحرارة = ${telemetryData['temperature']}°C');
      } else {
        print(
            '⚠️ [خطأ ${response.statusCode}] تم رفض البيانات: ${response.body}');
        // إذا انتهت صلاحية التوكن، يمكن إضافة منطق هنا لإعادة تسجيل الدخول
      }
    } catch (e) {
      print('❌ [خطأ اتصال] لم يتم إرسال البيانات: $e');
    }
  });
}
