import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 
import 'package:plant_monitor/constants.dart';
import 'package:plant_monitor/main.dart';
import 'package:plant_monitor/data/diseases_data.dart';

class PlantDoctorScreen extends StatefulWidget {
  const PlantDoctorScreen({super.key});

  @override
  State<PlantDoctorScreen> createState() => _PlantDoctorScreenState();
}

class _PlantDoctorScreenState extends State<PlantDoctorScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  XFile? _selectedImageXFile;
  bool _isAnalyzing = false;
  
  List<Map<String, dynamic>> _scanHistory = [];

  final String _apiUrl = 'https://d1nhgyb1fjl6pc.cloudfront.net/predict';

  // ✅ دالة ديناميكية لإنشاء مفتاح خاص بكل فلاح في الويب
  // ✅ دالة ديناميكية لإنشاء مفتاح خاص بكل فلاح في الويب (بدون Supabase)
  Future<String> get _userKey async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest_user';
    return 'web_scan_history_$userId';
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // --- دوال السجل للويب ---
  
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String key = await _userKey; // 👈 التعديل هنا
    List<String> historyStrings = prefs.getStringList(key) ?? [];
    setState(() {
      _scanHistory = historyStrings.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveToHistory(Disease disease, String confidence) async {
    final prefs = await SharedPreferences.getInstance();
    String key = await _userKey; // 👈 التعديل هنا
    List<String> historyStrings = prefs.getStringList(key) ?? []; 

    final formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    Map<String, dynamic> newScan = {
      'diseaseLabel': disease.modelLabel, 
      'confidence': confidence,
      'date': formattedDate,
    };
    historyStrings.insert(0, json.encode(newScan));

    if (historyStrings.length > 20) {
      historyStrings = historyStrings.sublist(0, 20);
    }

    await prefs.setStringList(key, historyStrings); 
    _loadHistory();
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String key = await _userKey; // 👈 التعديل هنا
    await prefs.remove(key);
    
    setState(() {
      _scanHistory = [];
    });
  }

  // ----------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageXFile = image;
          _isAnalyzing = true;
        });
        
        await Future.delayed(const Duration(milliseconds: 100));
        await _uploadAndAnalyze(bytes, image.name);
      }
    } catch (e) {
      print("Error picking image: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _uploadAndAnalyze(Uint8List imageBytes, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);
        String label = jsonResponse['diseaseLabel'];
        String confidenceStr = jsonResponse['confidence'].toString();

        Disease detectedDisease;
        try {
          detectedDisease = tomatoDiseases.firstWhere((d) => d.modelLabel.toLowerCase() == label.toLowerCase());
        } catch (e) {
          detectedDisease = tomatoDiseases.firstWhere((d) => d.modelLabel == 'healthy');
        }

        if (mounted) {
          setState(() => _isAnalyzing = false);
          _showResultDialog(detectedDisease, confidenceStr);
          await _saveToHistory(detectedDisease, confidenceStr); 
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Cloud API Error: $e");
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(languageNotifier.value ? 'خطأ في الاتصال بالخادم السحابي' : 'Cloud Server Connection Error'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSmartScanTips(BuildContext context) {
    final isArabic = languageNotifier.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.tips_and_updates, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Text(isArabic ? 'نصائح لنتيجة دقيقة' : 'Tips for Best Results', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTipItem(Icons.center_focus_strong, isArabic ? 'قرب الكاميرا من الورقة المصابة فقط.' : 'Focus close on the infected leaf.'),
            _buildTipItem(Icons.wb_sunny, isArabic ? 'تأكد من وجود إضاءة جيدة.' : 'Ensure good lighting.'),
            _buildTipItem(Icons.wallpaper, isArabic ? 'خلفية بسيطة (يفضل غير مزدحمة).' : 'Use a clean, simple background.'),
            _buildTipItem(Icons.blur_off, isArabic ? 'ثبت يدك لمنع اهتزاز الصورة.' : 'Hold steady to avoid blur.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showImageSourceActionSheet(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(isArabic ? 'ابدأ الفحص' : 'Start Scan', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    final isArabic = languageNotifier.value;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: Text(isArabic ? 'اختيار من المعرض' : 'Choose from Gallery'),
              onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.accentColor),
              title: Text(isArabic ? 'الكاميرا' : 'Camera'),
              onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.camera); },
            ),
          ],
        ),
      ),
    );
  }

  void _showHistorySheet() {
    final isArabic = languageNotifier.value;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isArabic ? 'سجل الفحوصات' : 'History (Last 20)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await _clearHistory();
                        setModalState(() {}); 
                        Navigator.pop(context); 
                      },
                    )
                  ],
                ),
                const Divider(),
                Expanded(
                  child: _scanHistory.isEmpty
                      ? Center(child: Text(isArabic ? 'لا يوجد سجلات بعد' : 'No history yet', style: const TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _scanHistory.length,
                          itemBuilder: (context, index) {
                            final item = _scanHistory[index];
                            final disease = tomatoDiseases.firstWhere(
                              (d) => d.modelLabel == item['diseaseLabel'],
                              orElse: () => tomatoDiseases.firstWhere((d) => d.modelLabel == 'healthy'),
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(disease.imagePath, width: 50, height: 50, fit: BoxFit.cover, 
                                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                                ),
                                title: Text(isArabic ? disease.nameAr : disease.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${item['date']}\n${isArabic ? 'الثقة' : 'Confidence'}: ${item['confidence']}%"),
                                
                                trailing: IconButton(
                                  icon: const Icon(Icons.share, color: AppColors.accentColor, size: 20),
                                  onPressed: () {
                                    String shareText = isArabic
                                        ? "فحص سحابي من طبيب النبات:\nالمرض: ${disease.nameAr}\nالثقة: ${item['confidence']}%\nالتاريخ: ${item['date']}"
                                        : "Cloud Diagnosis from Plant Doctor:\nDisease: ${disease.name}\nConfidence: ${item['confidence']}%\nDate: ${item['date']}";
                                    Share.share(shareText);
                                  },
                                ),
                                onTap: () => _showTreatmentDetails(disease),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showResultDialog(Disease disease, String confidence) {
     final isArabic = languageNotifier.value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            
            // ✅ تم تعديل عرض الصورة لـ BoxFit.contain مع خلفية أنيقة
            if (_selectedImageBytes != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(_selectedImageBytes!, fit: BoxFit.contain),
                ),
              ),
            
            const SizedBox(height: 20),
            
            Text(
              isArabic ? disease.nameAr : disease.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: disease.modelLabel == 'healthy' ? Colors.green : Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${isArabic ? "نسبة الثقة" : "Confidence"}: $confidence%',
                style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              isArabic ? disease.descriptionAr : disease.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                       String text = isArabic
                          ? "تشخيص سحابي من طبيب النبات:\nالمرض: ${disease.nameAr}\nنسبة الثقة: $confidence%\nالعلاج: ${disease.treatmentAr}"
                          : "Cloud Diagnosis from Plant Doctor:\nDisease: ${disease.name}\nConfidence: $confidence%\nTreatment: ${disease.treatment}";
                      
                      Share.share(text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.share, color: AppColors.accentColor),
                  ),
                ),
                
                const SizedBox(width: 10),

                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showTreatmentDetails(disease);
                    },
                    icon: const Icon(Icons.medical_services_outlined, color: Colors.white),
                    label: Text(isArabic ? 'التشخيص والعلاج' : 'Diagnosis & Treatment', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTreatmentDetails(Disease disease) {
    final isArabic = languageNotifier.value;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isArabic ? 'خطة العلاج' : 'Treatment Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.red[400], size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic ? disease.nameAr : disease.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(isArabic ? '🔍 الأعراض والوصف' : '🔍 Symptoms'),
              Text(
                isArabic ? disease.descriptionAr : disease.description,
                style: TextStyle(fontSize: 15, color: textColor?.withOpacity(0.8), height: 1.5),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(isArabic ? '💊 خطوات العلاج' : '💊 Treatment Steps'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  isArabic ? disease.treatmentAr : disease.treatment,
                  style: const TextStyle(fontSize: 16, color: Colors.green, height: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = languageNotifier.value;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isArabic ? "طبيب النبات (سحابي)" : "Plant Doctor (Cloud)", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.accentColor, size: 28),
            tooltip: isArabic ? 'السجل' : 'History',
            onPressed: () => _showHistorySheet(), 
          ),
          const SizedBox(width: 15),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSmartScanTips(context),
        label: Text(isArabic ? 'فحص جديد' : 'New Scan', style: const TextStyle(color: Colors.white)),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        backgroundColor: AppColors.accentColor,
      ),
      body: _isAnalyzing 
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 20), Text(isArabic ? 'جاري التحليل سحابياً...' : 'Analyzing via cloud...')]))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tomatoDiseases.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isArabic ? 'موسوعة الأمراض' : 'Disease Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                      Text(isArabic ? 'قائمة بأشهر أمراض الطماطم' : 'Common tomato diseases', style: TextStyle(color: textColor?.withOpacity(0.6))),
                    ],
                  ),
                );
              }
              final disease = tomatoDiseases[index - 1];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(disease.imagePath),
                    backgroundColor: Colors.grey[200],
                    onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
                  ),
                  title: Text(isArabic ? disease.nameAr : disease.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTreatmentDetails(disease),
                ),
              );
            },
          ),
    );
  }
}