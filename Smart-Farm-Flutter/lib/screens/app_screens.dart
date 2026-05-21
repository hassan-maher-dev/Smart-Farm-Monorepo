import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_monitor/constants.dart';
import 'package:plant_monitor/widgets/common_widgets.dart';
import 'package:plant_monitor/screens/login_screen.dart';
import 'package:plant_monitor/main.dart';

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
  if (_sensorTitlesAr.containsKey(text)) return _sensorTitlesAr[text]!;
  if (_sensorDescAr.containsKey(text)) return _sensorDescAr[text]!;
  return text;
}

// -------------------- 1. Dashboard Screen --------------------
class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> currentData;
  final DateTime currentTime;
  final String Function(String, String) getSensorValue;

  const DashboardScreen({
    super.key,
    required this.currentData,
    required this.currentTime,
    required this.getSensorValue,
  });

  Map<String, dynamic> _getWeatherStatus(bool isArabic) {
    final tempVal = currentData['temperature'] ?? 0;
    double temp = (tempVal is num) ? tempVal.toDouble() : double.tryParse(tempVal.toString()) ?? 0.0;
    double feelsLike = temp + 1.2;
    String statusText;
    String descText;
    IconData icon;
    Color color;

    if (temp > 30) {
      statusText = isArabic ? 'مشمس' : 'Sunny';
      descText = isArabic ? 'صافي ومشمس' : 'Clear and sunny';
      icon = Icons.wb_sunny_rounded;
      color = Colors.orange;
    } else if (temp >= 15) {
      statusText = isArabic ? 'غائم' : 'Cloudy';
      descText = isArabic ? 'غائم جزئياً' : 'Partly cloudy sky';
      icon = Icons.wb_cloudy_rounded;
      color = Colors.amber;
    } else {
      statusText = isArabic ? 'بارد' : 'Cold';
      descText = isArabic ? 'أجواء باردة' : 'Low temperature';
      icon = Icons.ac_unit_rounded;
      color = Colors.cyan;
    }

    return {
      'temp': temp.toStringAsFixed(1),
      'feelsLike': feelsLike.toStringAsFixed(1),
      'status': statusText,
      'desc': descText,
      'icon': icon,
      'color': color
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : screenWidth > 800 ? 3 : 2;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isArabic = languageNotifier.value;
    
    final weather = _getWeatherStatus(isArabic);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Theme.of(context).cardColor,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.eco, size: 28, color: AppColors.accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isArabic ? 'مزرعتي الذكية' : 'FarmNet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                        Text(isArabic ? 'نظام الزراعة الذكي' : 'Smart Agriculture', style: TextStyle(fontSize: 11, color: textColor?.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('HH:mm').format(currentTime), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      Text(DateFormat('dd MMM').format(currentTime), style: TextStyle(fontSize: 10, color: textColor?.withOpacity(0.7))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),

          // Weather Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'الطقس الحالي' : 'CURRENT WEATHER',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: textColor?.withOpacity(0.6),
                          letterSpacing: 0.5
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: weather['color'].withOpacity(0.1), 
                          shape: BoxShape.circle, 
                        ),
                        child: Icon(weather['icon'], color: weather['color'], size: 24),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    weather['status'],
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: weather['color'] 
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weather['desc'],
                    style: TextStyle(
                      fontSize: 12, 
                      color: textColor?.withOpacity(0.5)
                    ),
                  ),
                  
                  const SizedBox(height: 24), 
                  
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'الشعور الحقيقي' : 'FEELS LIKE',
                            style: TextStyle(fontSize: 10, color: textColor?.withOpacity(0.6), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${weather['feelsLike']}°C',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 40), 
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'درجة الحرارة' : 'TEMPERATURE',
                            style: TextStyle(fontSize: 10, color: textColor?.withOpacity(0.6), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${weather['temp']}°C',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          
          if (currentData.isNotEmpty && currentData['timestamp'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
              isArabic 
                ? 'آخر تحديث: ${DateFormat('hh:mm a').format(DateTime.parse(currentData['timestamp'].toString()).toLocal())}'
                : 'Last Update: ${DateFormat('hh:mm a').format(DateTime.parse(currentData['timestamp'].toString()).toLocal())}',
              style: TextStyle(fontSize: 10, color: textColor?.withOpacity(0.5)),
            ),
            ),
            
          const SizedBox(height: 12),
          
          // Sensors Grid
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              for (var sensor in sensorsList)
                ModernCard(
                  title: _translate(sensor['name'], isArabic),
                  value: getSensorValue(sensor['value_key'], sensor['unit']),
                  subtitle: _translate(sensor['description'], isArabic),
                  icon: sensor['icon'],
                  color: sensor['color'],
                  type: sensor['type'],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------- 2. Sensors Screen --------------------

class SensorsScreen extends StatefulWidget {
  final Map<String, dynamic> currentData;
  final List<Map<String, dynamic>> historicalData;
  final String Function(String, String) getSensorValue;

  const SensorsScreen({
    super.key,
    required this.currentData,
    required this.historicalData,
    required this.getSensorValue,
  });
  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  String? _selectedSensorName;
  @override
  Widget build(BuildContext context) {
    if (_selectedSensorName != null) {
      return _buildSensorDetail(_selectedSensorName!);
    }
    return _buildSensorsList();
  }

  Widget _buildSensorsList() {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isArabic = languageNotifier.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            elevation: 0,
            color: AppColors.accentColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.accentColor, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic ? 'اضغط على أي حساس لعرض التحليل البياني' : 'Select a sensor for detailed analytics',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...sensorsList.map((sensor) => Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Theme.of(context).cardColor,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sensor['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(sensor['icon'], color: sensor['color']),
              ),
              title: Text(_translate(sensor['name'], isArabic), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              trailing: Text(
                widget.getSensorValue(sensor['value_key'], sensor['unit']),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sensor['color']),
              ),
              onTap: () {
                setState(() {
                  _selectedSensorName = sensor['name'];
                });
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSensorDetail(String sensorName) {
    final sensor = sensorsList.firstWhere((s) => s['name'] == sensorName);
    final rawChartData = _getRawChartData(); 
    final stats = _getStats(sensor['value_key']); 
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isArabic = languageNotifier.value;
    
    final rawVal = widget.currentData[sensor['value_key']];
    double currentVal = (rawVal is num) ? rawVal.toDouble() : double.tryParse(rawVal?.toString() ?? '0') ?? 0.0;
    
    String statusStr = isArabic ? "طبيعية 😊" : "Normal 😊";
    Color statusColor = Colors.green;
    if (stats['avg'] > 0) {
      if (currentVal > stats['avg'] * 1.15) {
        statusStr = isArabic ? "مرتفعة ⚠️" : "High ⚠️";
        statusColor = Colors.orange;
      } else if (currentVal < stats['avg'] * 0.85) {
        statusStr = isArabic ? "منخفضة ❄️" : "Low ❄️";
        statusColor = Colors.blue;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: textColor),
                    onPressed: () => setState(() => _selectedSensorName = null),
                  ),
                  Text(
                    _translate(sensorName, isArabic),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: stats['max'] > 0 ? (currentVal / (stats['max'] * 1.2)).clamp(0.0, 1.0) : 0.5,
                      strokeWidth: 15,
                      backgroundColor: sensor['color'].withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(sensor['color']),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.getSensorValue(sensor['value_key'], sensor['unit']),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(statusStr, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(child: _buildSmallStatCard(isArabic ? 'أعلى قيمة' : 'Max', '${stats['max'].toStringAsFixed(1)}${sensor['unit']}', stats['maxTime'], Colors.redAccent, Icons.arrow_upward, cardBgColor, textColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSmallStatCard(isArabic ? 'أقل قيمة' : 'Min', '${stats['min'].toStringAsFixed(1)}${sensor['unit']}', stats['minTime'], Colors.blueAccent, Icons.arrow_downward, cardBgColor, textColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSmallStatCard(isArabic ? 'المتوسط اليومي' : 'Avg Today', '${stats['avg'].toStringAsFixed(1)}${sensor['unit']}', '', Colors.amber.shade600, Icons.stacked_line_chart, cardBgColor, textColor)),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, color: sensor['color']),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'الرسم البياني المباشر' : 'Live Trend',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),

                    SizedBox(
                      height: 260,
                      width: double.infinity,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                interval: 1, 
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < rawChartData.length) {
                                    String timeStr = '';
                                    if (rawChartData[index]['timestamp'] != null) {
                                      try {
                                        DateTime dt = DateTime.parse(rawChartData[index]['timestamp']).toLocal();
                                        timeStr = DateFormat('hh:mm:ss').format(dt); 
                                      } catch (e) {}
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: RotatedBox(
                                        quarterTurns: 3, 
                                        child: Text(timeStr, style: TextStyle(color: textColor?.withOpacity(0.5), fontSize: 10)),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: rawChartData.asMap().entries.map((e) {
                                final val = e.value[sensor['value_key']];
                                final yVal = (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
                                return FlSpot(e.key.toDouble(), yVal);
                              }).toList(),
                              isCurved: true, 
                              color: sensor['color'],
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true), 
                              belowBarData: BarAreaData(
                                show: true,
                                color: sensor['color'].withOpacity(0.2), 
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, String subValue, Color color, IconData icon, Color bgColor, Color? textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: textColor?.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
          ),
          if (subValue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subValue, 
              style: TextStyle(fontSize: 10, color: textColor?.withOpacity(0.5)),
            )
          ]
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getRawChartData() {
    if (widget.historicalData.isEmpty) return [];
    return widget.historicalData.length > 20 
        ? widget.historicalData.sublist(widget.historicalData.length - 20) 
        : widget.historicalData;
  }

  Map<String, dynamic> _getStats(String key) {
    if (widget.historicalData.isEmpty) return {'min': 0.0, 'max': 0.0, 'avg': 0.0, 'minTime': '', 'maxTime': ''};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    double min = double.infinity;
    double max = double.negativeInfinity;
    String minTime = '';
    String maxTime = '';
    double sum = 0;
    int count = 0;
    for (var d in widget.historicalData) {
      if (d['timestamp'] == null) continue;
      try {
        DateTime dt = DateTime.parse(d['timestamp']).toLocal();
        if (dt.isAfter(todayStart)) {
          final val = (d[key] is num) ? d[key].toDouble() : double.tryParse(d[key].toString());
          if (val != null) {
            String timeStr = DateFormat('hh:mm a').format(dt);
            if (languageNotifier.value) {
              timeStr = timeStr.replaceAll('AM', 'ص').replaceAll('PM', 'م');
            }

            if (val < min) { min = val; minTime = timeStr; }
            if (val > max) { max = val; maxTime = timeStr; }
            sum += val;
            count++;
          }
        }
      } catch (e) {}
    }
    
    if (count == 0) return {'min': 0.0, 'max': 0.0, 'avg': 0.0, 'minTime': '', 'maxTime': ''};
    if (min == double.infinity) min = 0.0;
    if (max == double.negativeInfinity) max = 0.0;
    return {'min': min, 'max': max, 'avg': sum / count, 'minTime': minTime, 'maxTime': maxTime};
  }
}

// -------------------- 3. Control Screen --------------------
class ControlScreen extends StatelessWidget {
  final Map<String, dynamic> devicesState;
  final Function(String, bool, {int duration}) onControlDevice;
  final Function(String) onSetAutoMode; 

  const ControlScreen({
    super.key, 
    required this.devicesState, 
    required this.onControlDevice,
    required this.onSetAutoMode, 
  });
  @override
  Widget build(BuildContext context) {
    final isArabic = languageNotifier.value;
    
    bool pumpOn = devicesState['water_pump']?['is_on'] ?? false;
    String pumpMode = devicesState['water_pump']?['mode'] ?? 'auto'; 

    bool lightOn = devicesState['grow_lights']?['is_on'] ?? false;
    String lightMode = devicesState['grow_lights']?['mode'] ?? 'auto';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildDeviceCard(
            context, 
            isArabic ? 'إضاءة النمو' : 'Grow Lights', 
            'grow_lights', 
            Icons.lightbulb, 
            Colors.amber, 
            isArabic ? 'حالة الجهاز: ${lightOn ? "يعمل" : "متوقف"}' : 'Status: ${lightOn ? "ON" : "OFF"}',
            isOn: lightOn,
            mode: lightMode, 
          ),
          const SizedBox(height: 12),
          _buildDeviceCard(
            context, 
            isArabic ? 'مضخة المياه' : 'Water Pump', 
            'water_pump', 
            Icons.water_drop, 
            Colors.blue, 
            isArabic ? 'حالة الجهاز: ${pumpOn ? "يعمل" : "متوقف"}' : 'Status: ${pumpOn ? "ON" : "OFF"}',
            duration: 2,
            isOn: pumpOn,
            mode: pumpMode, 
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, String title, String key, IconData icon, Color color, String autoInfo, {int duration = 0, required bool isOn, required String mode}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isArabic = languageNotifier.value;
    
    bool isManual = mode == 'manual';
    bool isAuto = !isManual;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 28, color: isOn ? color : Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      Text(isOn ? (isArabic ? 'مشغل' : 'ON - Active') : (isArabic ? 'متوقف' : 'OFF - Inactive'), style: TextStyle(fontSize: 11, color: textColor?.withOpacity(0.6))),
                      Text(
                        isManual ? (isArabic ? 'الوضع: يدوي ✋' : 'Mode: Manual ✋') : (isArabic ? 'الوضع: تلقائي 🤖' : 'Mode: Auto 🤖'), 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isManual ? Colors.redAccent : Colors.green)
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOn,
                  onChanged: (value) => onControlDevice(key, value, duration: duration),
                  activeThumbColor: color,
                  activeTrackColor: color.withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            ElevatedButton.icon(
              onPressed: () {
                if (isAuto) {
                  onControlDevice(key, isOn, duration: duration);
                } else {
                  onSetAutoMode(key);
                }
              },
              icon: Icon(isAuto ? Icons.pan_tool_outlined : Icons.autorenew),
              label: Text(
                isAuto 
                  ? (isArabic ? 'تفعيل التحكم اليدوي' : 'Enable Manual Mode') 
                  : (isArabic ? 'تفعيل الوضع التلقائي' : 'Enable Auto Mode')
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuto ? Colors.orange.shade400 : Colors.green.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppColors.accentColor, size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(autoInfo, style: TextStyle(fontSize: 11, color: textColor?.withOpacity(0.6)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- 4. About Screen --------------------
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isArabic = languageNotifier.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E2130) : Colors.white;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2A26), 
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: AppColors.accentColor.withOpacity(0.3), blurRadius: 40, spreadRadius: 5),
                  ],
                ),
                child: const Icon(Icons.eco, size: 70, color: AppColors.accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'فارم نت' : 'FarmNet',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 1.0),
              ),
              const SizedBox(height: 25),

              _buildSectionCard(
                context, 
                title: isArabic ? 'ماذا نقدم في فارم نت؟' : 'What FarmNet Offers?', 
                cardBgColor: cardBgColor,
                child: Text(
                  isArabic 
                    ? 'نقدم حلولاً ذكية شاملة تدمج بين الـ IoT والذكاء الاصطناعي. يقوم نظامنا بمراقبة حيوية لظروف التربة والجو وتوفير تحكم ذكي عن بُعد في أنظمة الري والإضاءة، بالإضافة إلى استخدام تقنيات رؤية الكمبيوتر لتشخيص أمراض النباتات.' 
                    : 'We provide smart solutions merging IoT and AI. Our system delivers real-time monitoring of soil and environmental conditions with remote intelligent control, utilizing computer vision to diagnose plant diseases.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: textColor?.withOpacity(0.8), height: 1.6),
                ),
              ),

              _buildSectionCard(
                context, 
                title: isArabic ? 'لجنة الإشراف' : 'Supervisors', 
                cardBgColor: cardBgColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accentColor.withOpacity(0.2),
                      radius: 20,
                      child: const Icon(Icons.school, color: AppColors.accentColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isArabic ? 'د. ريم حمادة' : 'Dr. Reem Hamada',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),

              _buildSectionCard(
                context, 
                title: isArabic ? 'فريق العمل' : 'The Team', 
                cardBgColor: cardBgColor,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTeamMemberCard(context, 'Hazem Nasr', isDark, textColor),
                    _buildTeamMemberCard(context, isArabic ? 'أحمد علي' : 'Ahmed Ali', isDark, textColor),
                    _buildTeamMemberCard(context, isArabic ? 'سارة محمد' : 'Sara Mohamed', isDark, textColor),
                    _buildTeamMemberCard(context, isArabic ? 'محمود حسن' : 'Mahmoud Hassan', isDark, textColor),
                    _buildTeamMemberCard(context, isArabic ? 'ليلى إبراهيم' : 'Layla Ibrahim', isDark, textColor),
                    _buildTeamMemberCard(context, isArabic ? 'ياسين أحمد' : 'Yassin Ahmed', isDark, textColor),
                    _buildTeamMemberCard(context, isArabic ? 'نور سليم' : 'Nour Selim', isDark, textColor),
                  ],
                ),
              ),

              Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 8, left: 8),
                  child: Text(
                    isArabic ? 'المجالات التقنية' : 'Core Tech Domains', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTechCard(context, isArabic ? 'تطبيقات موبايل' : 'Mobile App', Icons.phone_android, Colors.blue, cardBgColor, textColor),
                  _buildTechCard(context, 'IoT', Icons.settings_input_component, Colors.orange, cardBgColor, textColor),
                  _buildTechCard(context, isArabic ? 'حوسبة سحابية' : 'Cloud', Icons.cloud_queue, Colors.green, cardBgColor, textColor),
                  _buildTechCard(context, 'AI & ML', Icons.psychology, Colors.purple, cardBgColor, textColor),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required Widget child, required Color cardBgColor}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor?.withOpacity(0.7))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(BuildContext context, String name, bool isDark, Color? textColor) {
    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 2.1, 
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262A3D) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.accentColor.withOpacity(0.2),
            child: const Icon(Icons.person, size: 16, color: AppColors.accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name, 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechCard(BuildContext context, String title, IconData icon, Color iconColor, Color cardBgColor, Color? textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 9, color: textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// -------------------- 5. Settings Screen --------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadFarmName();
  }

  Future<void> _loadFarmName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameController.text = prefs.getString('farm_name') ?? "My Green Farm";
      });
    }
  }

  Future<void> _saveFarmName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farm_name', value);
  }

  // ✅ تعديل دالة تسجيل الخروج الخاصة بـ SharedPreferences
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // مسح كل البيانات
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging out: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isArabic = languageNotifier.value;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: AppColors.accentColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.accentColor.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 35, color: AppColors.accentColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isArabic ? 'مرحباً، مالك المزرعة' : 'Welcome, Farm Owner', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _nameController,
                          onChanged: _saveFarmName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                            hintText: isArabic ? 'اسم المزرعة' : 'Farm Name',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionHeader(isArabic ? 'إعدادات التطبيق' : 'App Settings', textColor, isArabic),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(isArabic ? 'اللغة' : 'Language', style: TextStyle(color: textColor)),
                  subtitle: Text(isArabic ? 'العربية' : 'English', style: TextStyle(color: textColor?.withOpacity(0.6))),
                  value: isArabic,
                  activeThumbColor: AppColors.accentColor,
                  onChanged: (val) async {
                    languageNotifier.value = val;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('is_arabic', val);
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, currentMode, child) {
                    final isDark = currentMode == ThemeMode.dark;
                    return SwitchListTile(
                      title: Text(isArabic ? 'الوضع الليلي' : 'Dark Mode', style: TextStyle(color: textColor)),
                      secondary: Icon(Icons.dark_mode, color: isDark ? Colors.purple : Colors.grey),
                      value: isDark,
                      activeThumbColor: Colors.purple,
                      onChanged: (val) async {
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('is_dark', val);
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionHeader(isArabic ? 'المساعدة والدعم' : 'Help & Support', textColor, isArabic),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.headset_mic, color: Colors.orange),
                  title: Text(isArabic ? 'كلم الدعم الفني' : 'Call Technical Support', style: TextStyle(color: textColor)),
                  subtitle: const Text('+20 123 456 7890'),
                  trailing: const Icon(Icons.phone, color: Colors.green),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isArabic ? 'جاري الاتصال...' : 'Calling Support...')));
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: Text(isArabic ? 'تسجيل الخروج' : 'Sign Out', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            "Version 1.0.0",
            style: TextStyle(
              color: textColor?.withOpacity(0.4) ?? Colors.grey, 
              fontSize: 12,
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color? textColor, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Align(
        alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor?.withOpacity(0.6) ?? Colors.grey),
        ),
      ),
    );
  }
}

// -------------------- 6. Notifications Screen --------------------
class NotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> historicalData;
  const NotificationsScreen({super.key, required this.historicalData});

  List<Map<String, dynamic>> _generateAlerts(bool isArabic) {
    List<Map<String, dynamic>> alerts = [];
    if (historicalData.isEmpty) {
      alerts.add({
        'type': 'info',
        'title': isArabic ? 'انتظار البيانات' : 'Waiting for Data',
        'message': isArabic ? 'جاري الاتصال بالحساسات...' : 'Connecting to sensors...',
        'time': 'Now'
      });
      return alerts;
    }

    int lastTempState = 0;
    int lastMoistureState = 0;

    for (var record in historicalData) {
      final temp = (record['temperature'] is num) ? record['temperature'] : 0;
      final moisture = (record['soil_moisture'] is num) ? record['soil_moisture'] : 0;
      String timeStr = '--:--';
      
      if (record['timestamp'] != null) {
        try {
          DateTime parsedDate = DateTime.parse(record['timestamp'].toString()).toLocal();
          timeStr = DateFormat('hh:mm a').format(parsedDate);
        } catch (e) {
          timeStr = '--:--';
        }
      }

      int currentTempState = 0;
      if (temp > 30) currentTempState = 1;

      if (currentTempState != lastTempState) {
        if (currentTempState == 1) {
          alerts.add({
            'type': 'warning',
            'title': isArabic ? 'تنبيه حرارة مرتفعة' : 'High Temperature',
            'message': isArabic ? 'وصلت الحرارة إلى $temp°C' : 'Temperature reached $temp°C',
            'time': timeStr
          });
        }
        lastTempState = currentTempState;
      }

      int currentMoistureState = 0;
      if (moisture < 20) {
        currentMoistureState = 1;
      } else if (moisture > 80) {
        currentMoistureState = 2;
      }

      if (currentMoistureState != lastMoistureState) {
        if (currentMoistureState == 1) {
          alerts.add({
            'type': 'error',
            'title': isArabic ? 'التربة جافة جداً' : 'Critical Soil Moisture',
            'message': isArabic ? 'مستوى الرطوبة منخفض ($moisture%)' : 'Moisture level is critical ($moisture%)',
            'time': timeStr
          });
        } else if (currentMoistureState == 2) {
          alerts.add({
            'type': 'success',
            'title': isArabic ? 'تم الري' : 'Watering Detected',
            'message': isArabic ? 'التربة مشبعة بالمياه الآن' : 'Soil is well watered',
            'time': timeStr
          });
        }
        lastMoistureState = currentMoistureState;
      }
    }

    if (alerts.isEmpty) {
      alerts.add({
        'type': 'success',
        'title': isArabic ? 'النظام مستقر' : 'System Stable',
        'message': isArabic ? 'جميع القراءات في المعدل الطبيعي' : 'All readings are within normal range',
        'time': 'Now'
      });
    }

    return alerts.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isArabic = languageNotifier.value;

    final alerts = _generateAlerts(isArabic);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'سجل الأحداث' : 'Activity Log',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              if (alerts.length > 1)
                Icon(Icons.history, color: textColor?.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 10),

          ...alerts.map((alert) {
            Color color;
            IconData icon;
            
            switch(alert['type']) {
              case 'warning': color = Colors.orange; icon = Icons.warning_amber_rounded; break;
              case 'error': color = Colors.red; icon = Icons.error_outline; break;
              case 'success': color = Colors.green; icon = Icons.check_circle_outline; break;
              default: color = Colors.blue; icon = Icons.info_outline; break;
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Theme.of(context).cardColor,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  alert['title'],
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Text(
                  alert['message'],
                  style: TextStyle(color: textColor?.withOpacity(0.6), fontSize: 12),
                ),
                trailing: Text(
                  alert['time'],
                  style: TextStyle(fontSize: 11, color: textColor?.withOpacity(0.4)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}