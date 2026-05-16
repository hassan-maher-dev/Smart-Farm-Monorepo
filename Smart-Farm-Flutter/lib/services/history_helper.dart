import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ استدعاء Supabase

class HistoryHelper {
  
  // ✅ دالة ديناميكية بتجيب المفتاح بناءً على الـ ID بتاع الفلاح اللي مسجل دخول
  static String get _userKey {
    // هنجيب الـ ID من Supabase، لو مفيش حد مسجل (احتياطي) هنديها اسم default
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest_user';
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

    // ج. جلب القائمة القديمة الخاصة بالمستخدم الحالي فقط ✅
    String? oldData = prefs.getString(_userKey);
    List<dynamic> historyList = oldData != null ? json.decode(oldData) : [];

    // د. إضافة الجديد في الأول
    historyList.insert(0, newScan);

    // هـ. لو العدد زاد عن 20، امسح القديم
    if (historyList.length > 20) {
      // محاولة مسح الصورة القديمة لتوفير المساحة
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

    // و. الحفظ النهائي في ملف المستخدم الحالي ✅
    await prefs.setString(_userKey, json.encode(historyList));
  }

  // 2. دالة استرجاع السجل
  static Future<List<dynamic>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ استرجاع الداتا بناءً على اليوزر الحالي
    String? data = prefs.getString(_userKey); 
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
    // ✅ مسح سجل اليوزر الحالي فقط، وسيب سجلات الناس التانية
    await prefs.remove(_userKey); 
  }
}