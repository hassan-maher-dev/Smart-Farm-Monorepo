// lib/data/diseases_data.dart

class Disease {
  final String name;          // الاسم الانجليزي
  final String modelLabel;    // اسم الفولدر بالظبط (مهم جداً للذكاء الاصطناعي)
  final String nameAr;        // الاسم العربي
  final String imagePath;     // مسار الصورة
  final String description;   // الوصف
  final String descriptionAr; // الوصف عربي
  final String treatment;     // العلاج
  final String treatmentAr;   // العلاج عربي

  Disease({
    required this.name,
    required this.modelLabel,
    required this.nameAr,
    required this.imagePath,
    required this.description,
    required this.descriptionAr,
    required this.treatment,
    required this.treatmentAr,
  });
}

// القائمة الكاملة (11 صنف)
final List<Disease> tomatoDiseases = [
  // 1. Bacterial Spot
  Disease(
    name: 'Bacterial Spot',
    modelLabel: 'Bacterial_spot',
    nameAr: 'التبقع البكتيري',
    imagePath: 'assets/diseases/bacterial_spot.jpg',
    description: 'Small, dark, water-soaked spots on leaves. Leaves may turn yellow and drop.',
    descriptionAr: 'بقع داكنة مائية صغيرة تظهر على الأوراق. قد تصفر الأوراق وتتساقط.',
    treatment: 'Copper fungicides can help. Remove infected plant parts immediately.',
    treatmentAr: 'استخدم مبيدات فطرية نحاسية. أزل الأجزاء المصابة فوراً.',
  ),

  // 2. Early Blight
  Disease(
    name: 'Early Blight',
    modelLabel: 'Early_blight',
    nameAr: 'الندوة المبكرة',
    imagePath: 'assets/diseases/early_blight.jpg',
    description: 'Target-shaped spots with concentric rings on lower leaves.',
    descriptionAr: 'بقع دائرية تشبه "لوحة الهدف" (حلقات متداخلة) تظهر على الأوراق السفلية.',
    treatment: 'Improve air circulation. Water at the base. Apply fungicide if severe.',
    treatmentAr: 'حسن التهوية. اسقِ عند الجذور. استخدم مبيد فطري عند الضرورة.',
  ),

  // 3. Healthy
  Disease(
    name: 'Healthy',
    modelLabel: 'healthy',
    nameAr: 'نبات سليم',
    imagePath: 'assets/diseases/healthy.jpg',
    description: 'The plant shows no signs of disease. Leaves are green and vibrant.',
    descriptionAr: 'النبات يبدو بصحة جيدة والأوراق خضراء نضرة.',
    treatment: 'Keep up the good care! Maintain regular watering.',
    treatmentAr: 'استمر في العناية الجيدة وحافظ على انتظام الري.',
  ),

  // 4. Late Blight
  Disease(
    name: 'Late Blight',
    modelLabel: 'Late_blight',
    nameAr: 'الندوة المتأخرة',
    imagePath: 'assets/diseases/late_blight.jpg',
    description: 'Large, dark, greasy-looking spots. White mold may appear in wet weather.',
    descriptionAr: 'بقع كبيرة داكنة ودهنية. قد يظهر عفن أبيض في الجو الرطب.',
    treatment: 'Remove and destroy infected plants immediately. Use preventive fungicides.',
    treatmentAr: 'تخلص من النباتات المصابة فوراً (احرقها). استخدم مبيدات وقائية.',
  ),

  // 5. Leaf Mold
  Disease(
    name: 'Leaf Mold',
    modelLabel: 'Leaf_Mold',
    nameAr: 'عفن الأوراق',
    imagePath: 'assets/diseases/leaf_mold.jpg',
    description: 'Pale yellow spots on upper leaves, olive-green mold on the underside.',
    descriptionAr: 'بقع صفراء باهتة من الأعلى، وعفن زيتوني اللون أسفل الورقة.',
    treatment: 'Reduce humidity. Increase airflow. Avoid overhead watering.',
    treatmentAr: 'قلل الرطوبة وزود التهوية. تجنب الري بالرش.',
  ),

  // 6. Powdery Mildew (ده اللي كان ناقص) ✅
  Disease(
    name: 'Powdery Mildew',
    modelLabel: 'powdery_mildew',
    nameAr: 'البياض الدقيقي',
    imagePath: 'assets/diseases/powdery_mildew.jpg',
    description: 'White, powdery fungal growth on leaves, stems, and fruit.',
    descriptionAr: 'طبقة بيضاء تشبه الدقيق تظهر على الأوراق والسيقان.',
    treatment: 'Remove infected leaves. Spray with sulfur or baking soda solution.',
    treatmentAr: 'أزل الأوراق المصابة. رش النبات بالكبريت الميكروني أو محلول بيكربونات الصوديوم.',
  ),

  // 7. Septoria Leaf Spot
  Disease(
    name: 'Septoria Leaf Spot',
    modelLabel: 'Septoria_leaf_spot',
    nameAr: 'تبقع سبتوريا',
    imagePath: 'assets/diseases/septoria.jpg',
    description: 'Circular spots with gray centers and dark borders on lower leaves.',
    descriptionAr: 'بقع دائرية بمركز رمادي وحواف داكنة على الأوراق السفلية.',
    treatment: 'Remove fallen leaves. Keep leaves dry. Use fungicides.',
    treatmentAr: 'تخلص من الأوراق المتساقطة. حافظ على جفاف الأوراق.',
  ),

  // 8. Spider Mites
  Disease(
    name: 'Spider Mites',
    modelLabel: 'Spider_mites Two-spotted_spider_mite',
    nameAr: 'العنكبوت الأحمر',
    imagePath: 'assets/diseases/spider_mites.jpg',
    description: 'Tiny yellow specks on leaves. Fine webbing may be visible.',
    descriptionAr: 'نقاط صفراء صغيرة جداً. قد تلاحظ خيوط عنكبوتية دقيقة.',
    treatment: 'Spray with water to dislodge. Use Neem oil.',
    treatmentAr: 'رش بالماء بقوة. استخدم زيت النيم.',
  ),

  // 9. Target Spot
  Disease(
    name: 'Target Spot',
    modelLabel: 'Target_Spot',
    nameAr: 'التبقع المستهدف',
    imagePath: 'assets/diseases/target_spot.jpg',
    description: 'Brown lesions with concentric rings like a target.',
    descriptionAr: 'تقرحات بنية بحلقات دائرية تشبه الهدف.',
    treatment: 'Improve airflow. Apply appropriate fungicides.',
    treatmentAr: 'حسن التهوية واستخدم المبيدات المناسبة.',
  ),

  // 10. Tomato Mosaic Virus
  Disease(
    name: 'Mosaic Virus',
    modelLabel: 'Tomato_mosaic_virus',
    nameAr: 'فيروس التبرقش',
    imagePath: 'assets/diseases/mosaic_virus.jpg',
    description: 'Mottled light and dark green pattern on leaves.',
    descriptionAr: 'تبقعات متداخلة من الأخضر الفاتح والداكن على الأوراق.',
    treatment: 'No cure. Remove infected plants. Wash tools well.',
    treatmentAr: 'لا يوجد علاج. تخلص من النبات المصاب وعقم الأدوات.',
  ),

  // 11. Yellow Leaf Curl Virus
  Disease(
    name: 'Yellow Leaf Curl Virus',
    modelLabel: 'Tomato_Yellow_Leaf_Curl_Virus',
    nameAr: 'تجعد الأوراق الأصفر',
    imagePath: 'assets/diseases/yellow_curl.jpg',
    description: 'Leaves curl upward and turn yellow. Stunted growth.',
    descriptionAr: 'تجعد الأوراق لأعلى واصفرارها. توقف نمو النبات.',
    treatment: 'Control whiteflies (the carrier). Use resistant varieties.',
    treatmentAr: 'كافح الذبابة البيضاء (الناقل للمرض). ازرع أصناف مقاومة.',
  ),
];