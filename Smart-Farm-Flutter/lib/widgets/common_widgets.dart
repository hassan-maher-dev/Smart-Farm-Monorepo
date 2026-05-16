// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:plant_monitor/constants.dart';
import 'package:plant_monitor/main.dart'; 

// 1. القائمة الجانبية (Drawer)
class Sidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const Sidebar({super.key, required this.currentIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context) {
    final isArabic = languageNotifier.value;

    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: Column(
        children: [
          // رأس القائمة (Header)
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.accentColor),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.eco, color: AppColors.accentColor, size: 35),
            ),
            accountName: Text(isArabic ? 'مزرعتي الذكية' : 'FarmNet', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(isArabic ? 'نظام الزراعة الذكي' : 'Smart Agriculture System'),
          ),

          // عناصر القائمة
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, 0, Icons.grid_view_rounded, isArabic ? 'الرئيسية' : 'Home'),
                _buildDrawerItem(context, 1, Icons.sensors_rounded, isArabic ? 'الحساسات' : 'Sensors'),
                _buildDrawerItem(context, 2, Icons.smart_toy_rounded, isArabic ? 'التحكم' : 'Control'),
                _buildDrawerItem(context, 3, Icons.local_hospital_rounded, isArabic ? 'طبيب النبات' : 'Plant Doctor'),
                _buildDrawerItem(context, 5, Icons.notifications_rounded, isArabic ? 'تنبيهات' : 'Alerts'),
                _buildDrawerItem(context, 4, Icons.info_outline_rounded, isArabic ? 'عننا' : 'About'),
                const Divider(), // خط فاصل
                _buildDrawerItem(context, 6, Icons.settings_rounded, isArabic ? 'الإعدادات' : 'Settings'),
              ],
            ),
          ),
          
          // تذييل القائمة (رقم الإصدار)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, int index, IconData icon, String label) {
    bool isSelected = currentIndex == index;
    final color = isSelected ? AppColors.accentColor : Theme.of(context).textTheme.bodyLarge?.color;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.accentColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      onTap: () {
        onIndexChanged(index);
        Navigator.pop(context); // ✅ يقفل القائمة أوتوماتيك بعد الاختيار
      },
    );
  }
}

// 2. الكارت الحديث (ModernCard) - (لازم يفضل موجود)
class ModernCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String type;

  const ModernCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const Spacer(),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor?.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: textColor?.withOpacity(0.5))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _calculateProgress(value),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(String val) {
    try {
      String cleanVal = val.replaceAll(RegExp(r'[^\d.]'), '');
      double v = double.tryParse(cleanVal) ?? 0;
      if (val.contains('%')) return v / 100;
      if (val.contains('°C')) return v / 50; 
      if (val.contains('pH')) return v / 14;
      return 0.5;
    } catch (e) {
      return 0;
    }
  }
}