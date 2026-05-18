import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_monitor/constants.dart';
import 'package:plant_monitor/widgets/common_widgets.dart';
import 'package:plant_monitor/screens/login_screen.dart';
import 'package:plant_monitor/main.dart';
import 'package:fl_chart/fl_chart.dart';

// -------------------- قاموس الترجمة (Translation Map) --------------------

const Map<String, String> _sensorTitlesAr = {
  'SOIL MOISTURE': 'رطوبة التربة',
  'TEMPERATURE': 'درجة الحرارة',
  'HUMIDITY': 'الرطوبة الجوية',
  'LIGHT INTENSITY': 'شدة الإضاءة',
  'AIR QUALITY': 'جودة الهواء',
  'SOIL pH': 'حموضة التربة',
  'SOIL EC': 'ملوحة التربة',
  'WATER LEVEL': 'مستوى المياه',
  'UV INDEX': 'مؤشر UV',
};

const Map<String, String> _sensorDescAr = {
  'Soil Moisture percentage': 'نسبة الرطوبة في التربة',
  'Ambient temperature': 'درجة حرارة الجو المحيط',
  'Air humidity level': 'مستوى الرطوبة في الجو',
  'Light Intensity percentage': 'نسبة شدة الاضاءة',
  'Air Quality Index': 'مؤشر نقاء الهواء',
  'Soil acidity level': 'مستوى الحموضة والقلوية',
  'Electrical Conductivity': 'التوصيل الكهربائي للتربة',
  'Reservoir level': 'مستوى المياه في الخزان',
  'Sunlight intensity': 'شدة أشعة الشمس',
};

String _translate(String text, bool isArabic) {

  if (!isArabic) return text;

  if (_sensorTitlesAr.containsKey(text)) {
    return _sensorTitlesAr[text]!;
  }

  if (_sensorDescAr.containsKey(text)) {
    return _sensorDescAr[text]!;
  }

  return text;
}

// ===================================================
// ================= DASHBOARD SCREEN =================
// ===================================================

class DashboardScreen extends StatelessWidget {

  final Map<String, dynamic> currentData;

  final DateTime currentTime;

  final String Function(String, String)
      getSensorValue;

  const DashboardScreen({
    super.key,
    required this.currentData,
    required this.currentTime,
    required this.getSensorValue,
  });

  Map<String, dynamic> _getWeatherStatus(
    bool isArabic,
  ) {

    final tempVal =
        currentData['temperature'] ?? 0;

    double temp =
        (tempVal is num)
        ? tempVal.toDouble()
        : double.tryParse(tempVal.toString())
            ?? 0.0;

    double feelsLike = temp + 1.2;

    String statusText;

    String descText;

    IconData icon;

    Color color;

    if (temp > 30) {

      statusText =
          isArabic ? 'مشمس' : 'Sunny';

      descText =
          isArabic
          ? 'صافي ومشمس'
          : 'Clear and sunny';

      icon = Icons.wb_sunny_rounded;

      color = Colors.orange;

    } else if (temp >= 15) {

      statusText =
          isArabic ? 'غائم' : 'Cloudy';

      descText =
          isArabic
          ? 'غائم جزئياً'
          : 'Partly cloudy sky';

      icon = Icons.wb_cloudy_rounded;

      color = Colors.amber;

    } else {

      statusText =
          isArabic ? 'بارد' : 'Cold';

      descText =
          isArabic
          ? 'أجواء باردة'
          : 'Low temperature';

      icon = Icons.ac_unit_rounded;

      color = Colors.cyan;
    }

    return {
      'temp': temp.toStringAsFixed(1),
      'feelsLike':
          feelsLike.toStringAsFixed(1),
      'status': statusText,
      'desc': descText,
      'icon': icon,
      'color': color,
    };
  }

  @override
  Widget build(BuildContext context) {

    final textColor =
        Theme.of(context)
            .textTheme
            .bodyLarge
            ?.color;

    final isArabic =
        languageNotifier.value;

    final weather =
        _getWeatherStatus(isArabic);

    return SingleChildScrollView(

      padding: const EdgeInsets.all(12),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Card(

            elevation: 2,

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Padding(

              padding:
                  const EdgeInsets.all(16),

              child: Row(

                children: [

                  Container(

                    padding:
                        const EdgeInsets.all(10),

                    decoration: BoxDecoration(

                      color:
                          AppColors.accentColor
                              .withOpacity(0.1),

                      borderRadius:
                          BorderRadius.circular(10),
                    ),

                    child: const Icon(
                      Icons.eco,
                      size: 28,
                      color:
                          AppColors.accentColor,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(

                          isArabic
                              ? 'مزرعتي الذكية'
                              : 'FarmNet',

                          style: TextStyle(

                            fontSize: 16,

                            fontWeight:
                                FontWeight.bold,

                            color: textColor,
                          ),
                        ),

                        Text(

                          isArabic
                              ? 'نظام الزراعة الذكي'
                              : 'Smart Agriculture',

                          style: TextStyle(

                            fontSize: 11,

                            color:
                                textColor
                                    ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.end,

                    children: [

                      Text(

                        DateFormat(
                          'HH:mm',
                        ).format(currentTime),

                        style: TextStyle(

                          fontSize: 16,

                          fontWeight:
                              FontWeight.bold,

                          color: textColor,
                        ),
                      ),

                      Text(

                        DateFormat(
                          'dd MMM',
                        ).format(currentTime),

                        style: TextStyle(

                          fontSize: 10,

                          color:
                              textColor
                                  ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(

            elevation: 2,

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Padding(

              padding:
                  const EdgeInsets.all(20),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(

                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [

                      Text(

                        isArabic
                            ? 'الطقس الحالي'
                            : 'CURRENT WEATHER',

                        style: TextStyle(

                          fontSize: 12,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              textColor
                                  ?.withOpacity(0.6),
                        ),
                      ),

                      Icon(
                        weather['icon'],
                        color: weather['color'],
                        size: 26,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(

                    weather['status'],

                    style: TextStyle(

                      fontSize: 22,

                      fontWeight:
                          FontWeight.bold,

                      color: weather['color'],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(

                    weather['desc'],

                    style: TextStyle(

                      fontSize: 12,

                      color:
                          textColor
                              ?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================
// ================= SETTINGS SCREEN ==================
// ===================================================

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {

  final TextEditingController
      _nameController =
          TextEditingController();

  @override
  void initState() {

    super.initState();

    _loadFarmName();
  }

  Future<void> _loadFarmName() async {

    final prefs =
        await SharedPreferences.getInstance();

    if (mounted) {

      setState(() {

        _nameController.text =
            prefs.getString('farm_name')
            ?? "My Green Farm";
      });
    }
  }

  Future<void> _saveFarmName(
    String value,
  ) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'farm_name',
      value,
    );
  }

  // ✅ Flask Compatible Logout

  Future<void> _logout() async {

    try {

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'remember_me',
        false,
      );

      if (mounted) {

        Navigator.of(context)
            .pushAndRemoveUntil(

          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(),
          ),

          (route) => false,
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content: Text(
            'Logout Error: $e',
          ),

          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final textColor =
        Theme.of(context)
            .textTheme
            .bodyLarge
            ?.color;

    final isArabic =
        languageNotifier.value;

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Column(

        children: [

          Card(

            elevation: 4,

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),

            color: AppColors.accentColor,

            child: Padding(

              padding:
                  const EdgeInsets.all(20),

              child: Row(

                children: [

                  CircleAvatar(

                    radius: 30,

                    backgroundColor:
                        Colors.white,

                    child: const Icon(

                      Icons.person,

                      size: 35,

                      color:
                          AppColors.accentColor,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(

                    child: TextField(

                      controller:
                          _nameController,

                      onChanged:
                          _saveFarmName,

                      style:
                          const TextStyle(

                        fontSize: 18,

                        fontWeight:
                            FontWeight.bold,

                        color: Colors.white,
                      ),

                      decoration:
                          InputDecoration(

                        border:
                            InputBorder.none,

                        hintText:
                            isArabic
                            ? 'اسم المزرعة'
                            : 'Farm Name',

                        hintStyle:
                            TextStyle(

                          color:
                              Colors.white
                                  .withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(

            width: double.infinity,

            child: OutlinedButton.icon(

              onPressed: _logout,

              icon:
                  const Icon(Icons.logout),

              label: Text(

                isArabic
                    ? 'تسجيل الخروج'
                    : 'Sign Out',
              ),

              style: OutlinedButton.styleFrom(

                foregroundColor: Colors.red,

                side: const BorderSide(
                  color: Colors.red,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}