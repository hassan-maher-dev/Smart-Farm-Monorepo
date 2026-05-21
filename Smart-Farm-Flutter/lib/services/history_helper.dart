import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
// تم إزالة استدعاء مكتبة Supabase من هنا ✅

class HistoryHelper {
  
  // ✅ الدالة بقت async عشان بتجيب الـ user_id من SharedPreferences
  static Future<String> get _userKey async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest_user';
    return 'scan_history_$userId';
  }

  // 1. دالة حفظ نتيجة جديدة
  static Future<void> saveScan(File imageFile, String diseaseModelLabel, String confidence) async {
    final prefs = await SharedPreferences.getInstance();

    // أ. حفظ الصورة في مكان دائم في التطبيق
    final directory = await getApplicationDocumentsDirectory();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String savedPath = '${directory.path}/$fileName';
    
    // نسخ الصورة للمكان الجديد
    await imageFile.copy(savedPath);

    // ب. تجهيز البيانات (Map)
    Map<String, String> newScan = {
      'imagePath': savedPath,
      'diseaseLabel': diseaseModelLabel, 
      'confidence': confidence,
      'date': DateFormat('yyyy-MM-dd – hh:mm a').format(DateTime.now()),
    };

    // ✅ التعديل هنا: بنستنى المفتاح الأول
    String key = await _userKey; 
    
    // ج. جلب القائمة القديمة
    String? oldData = prefs.getString(key);
    List<dynamic> historyList = oldData != null ? json.decode(oldData) : [];

    // د. إضافة الجديد في الأول
    historyList.insert(0, newScan);

    // هـ. لو العدد زاد عن 20، امسح القديم
    if (historyList.length > 20) {
      try {
        var itemToRemove = historyList.last;
        File oldImage = File(itemToRemove['imagePath']);
        if (await oldImage.exists()) {
          await oldImage.delete();
        }
      } catch (e) {
        print("Error deleting old image: $e");
      }
      historyList.removeLast();
    }

    // و. الحفظ النهائي باستخدام المفتاح الجديد ✅
    await prefs.setString(key, json.encode(historyList));
  }

  // 2. دالة استرجاع السجل
  static Future<List<dynamic>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ التعديل هنا: بنستنى المفتاح الأول
    String key = await _userKey;
    String? data = prefs.getString(key);
    
    if (data == null) return [];
    return json.decode(data); // بيرجع List of Maps
  }

  // 3. مسح السجل بالكامل
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      List<dynamic> list = await getHistory();
      for (var item in list) {
        File img = File(item['imagePath']);
        if (await img.exists()) await img.delete();
      }
    } catch (e) {
      print("Error clearing history images: $e");
    }
    
    // ✅ التعديل هنا: بنستنى المفتاح عشان نمسح سجل اليوزر ده بس
    String key = await _userKey;
    await prefs.remove(key);
  }
}