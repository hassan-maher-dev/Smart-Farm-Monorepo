import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart'; // مكتبة الموديل
import 'package:image/image.dart' as img; // معالجة الصور
import 'package:share_plus/share_plus.dart'; // ✅ مكتبة المشاركة
import 'package:plant_monitor/constants.dart';
import 'package:plant_monitor/data/diseases_data.dart';
import 'package:plant_monitor/main.dart';
import 'package:plant_monitor/services/history_helper.dart'; // ملف السجل

class PlantDoctorScreen extends StatefulWidget {
  const PlantDoctorScreen({super.key});

  @override
  State<PlantDoctorScreen> createState() => _PlantDoctorScreenState();
}

class _PlantDoctorScreenState extends State<PlantDoctorScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  
  // متغيرات الموديل
  Interpreter? _interpreter;
  List<String>? _labels;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // 1. تحميل الموديل والأسماء
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/tflite/model.tflite');
      final labelData = await DefaultAssetBundle.of(context).loadString('assets/tflite/labels.txt');
      _labels = labelData.split('\n').where((s) => s.isNotEmpty).map((s) => s.trim()).toList();
      print("✅ Model Loaded Successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  // 2. تحليل الصورة
  Future<void> _runInference(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      print("⚠️ Model not loaded yet!");
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // أ. معالجة الصورة (224x224)
      final imageData = imageFile.readAsBytesSync();
      final image = img.decodeImage(imageData);
      final resizedImage = img.copyResize(image!, width: 224, height: 224);

      // ب. تحويل لمصفوفة أرقام (EfficientNet Preprocessing)
      // لاحظ: تم إزالة القسمة على 255.0 لأن EfficientNet يقوم بها داخلياً
      var input = List.generate(1, (i) => List.generate(224, (j) => List.generate(224, (k) => List.generate(3, (l) => 0.0))));

      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[0][y][x][0] = pixel.r.toDouble(); 
          input[0][y][x][1] = pixel.g.toDouble(); 
          input[0][y][x][2] = pixel.b.toDouble(); 
        }
      }

      // ج. تشغيل الموديل
      var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);
      _interpreter!.run(input, output);

      // د. استخراج النتيجة
      final prediction = output[0] as List<double>;
      double maxScore = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < prediction.length; i++) {
        if (prediction[i] > maxScore) {
          maxScore = prediction[i];
          maxIndex = i;
        }
      }

      final predictedLabel = _labels![maxIndex];
      final confidence = (maxScore * 100).toStringAsFixed(1);
      
      print("🔍 Result: $predictedLabel ($confidence%)");

      // هـ. البحث عن بيانات المرض
      Disease detectedDisease;
      try {
        detectedDisease = tomatoDiseases.firstWhere(
          (d) => d.modelLabel.toLowerCase() == predictedLabel.toLowerCase(),
        );
      } catch (e) {
        detectedDisease = tomatoDiseases.firstWhere((d) => d.modelLabel == 'healthy');
      }

      // ✅ و. حفظ النتيجة في السجل
      await HistoryHelper.saveScan(_selectedImage!, detectedDisease.modelLabel, confidence);

      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showResultDialog(detectedDisease, confidence);
      }

    } catch (e) {
      print("❌ Inference Error: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await Future.delayed(const Duration(milliseconds: 100));
        await _runInference(_selectedImage!);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // --- دوال العرض (UI Functions) ---

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
    bool isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(isArabic ? 'المعرض' : 'Gallery'),
              onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.gallery); },
            ),
            if (!isDesktop)
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(isArabic ? 'الكاميرا' : 'Camera'),
                onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.camera); },
              ),
            if (isDesktop)
               ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: Text(isArabic ? 'الكاميرا متاحة فقط على الهاتف' : 'Camera available on mobile only', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
      builder: (context) => Container(
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
                     await HistoryHelper.clearHistory();
                     Navigator.pop(context); 
                  },
                )
              ],
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: HistoryHelper.getHistory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(isArabic ? 'لا يوجد سجلات بعد' : 'No history yet', style: const TextStyle(color: Colors.grey)));
                  }
                  
                  final list = snapshot.data!;
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final disease = tomatoDiseases.firstWhere(
                        (d) => d.modelLabel == item['diseaseLabel'],
                        orElse: () => tomatoDiseases.firstWhere((d) => d.modelLabel == 'healthy'),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(item['imagePath']), width: 50, height: 50, fit: BoxFit.cover, 
                              errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                          ),
                          title: Text(isArabic ? disease.nameAr : disease.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${item['date']}\n${isArabic ? 'الثقة' : 'Confidence'}: ${item['confidence']}%"),
                          
                          // ✅ إضافة زرار المشاركة داخل كل عنصر في السجل
                          trailing: IconButton(
                            icon: const Icon(Icons.share, color: AppColors.accentColor, size: 20),
                            onPressed: () {
                              String shareText = isArabic
                                  ? "فحص من سجل تطبيق طبيب النبات:\nالمرض: ${disease.nameAr}\nالثقة: ${item['confidence']}%\nالتاريخ: ${item['date']}"
                                  : "Diagnosis from Plant Doctor History:\nDisease: ${disease.name}\nConfidence: ${item['confidence']}%\nDate: ${item['date']}";
                              Share.shareXFiles([XFile(item['imagePath'])], text: shareText);
                            },
                          ),
                          onTap: () => _showTreatmentDetails(disease),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
            
            if (_selectedImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05), // خلفية خفيفة عشان تبرز الصورة
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_selectedImage!, fit: BoxFit.contain),
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
                          ? "تشخيص تطبيق طبيب النبات:\nالمرض: ${disease.nameAr}\nنسبة الثقة: $confidence%\nالعلاج: ${disease.treatmentAr}"
                          : "Plant Doctor Diagnosis:\nDisease: ${disease.name}\nConfidence: $confidence%\nTreatment: ${disease.treatment}";
                      
                      if (_selectedImage != null) {
                        Share.shareXFiles([XFile(_selectedImage!.path)], text: text);
                      } else {
                        Share.share(text);
                      }
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
        title: Text(isArabic ? "طبيب النبات" : "Plant Doctor", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 20), Text(isArabic ? 'جاري تحليل ورقة النبات...' : 'Analyzing leaf...')]))
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