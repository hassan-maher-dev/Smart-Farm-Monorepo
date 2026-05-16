import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import 'package:plant_monitor/constants.dart';
import 'package:plant_monitor/widgets/common_widgets.dart';
import 'package:plant_monitor/screens/app_screens.dart';
import 'package:plant_monitor/screens/plant_doctor_screen.dart';
import 'package:plant_monitor/main.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  String? _userId;
  
  Map<String, dynamic> _currentData = {};
  bool _isLoading = true;
  int _currentIndex = 0;
  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;
  
  // حالة الأجهزة (Pump & Lights)
  Map<String, dynamic> _devicesState = {
    'water_pump': {'is_on': false, 'mode': 'auto'},
    'grow_lights': {'is_on': false, 'mode': 'auto'}
  };
  
  List<Map<String, dynamic>> _historicalData = [];

  @override
  void initState() {
    super.initState();
    _userId = _supabase.auth.currentUser?.id; 
    
    _startClockTimer();
    if (_userId != null) {
      _initializeApp();
    } else {
      print("Error: No user logged in!");
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  Future<void> _initializeApp() async {
    try {
      await _loadLatestData();
      await Future.wait([_loadHistoricalData(), _loadDevicesState()]);
      _setupRealtimeSubscription();
    } catch (e) {
      print('Error initializing: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // جلب آخر قراءة فورية
  Future<void> _loadLatestData() async {
    try {
      final response = await _supabase.from('plant_data')
          .select()
          .eq('user_id', _userId!)
          .order('timestamp', ascending: false)
          .limit(1);
          
      if (response.isNotEmpty && mounted) {
        setState(() {
          _currentData = Map<String, dynamic>.from(response[0]);
          _isLoading = false;
        });
        _updateHistoricalList(_currentData);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ جلب بيانات "اليوم فقط" بناءً على التاريخ (Logic المهندسين)
  Future<void> _loadHistoricalData() async {
    try {
      final now = DateTime.now();
      // بداية اليوم الحالي (12:00 AM) بصيغة ISO المتوافقة مع Supabase
      final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

      final response = await _supabase.from('plant_data')
          .select()
          .eq('user_id', _userId!)
          .gte('timestamp', todayStart) // هات القراءات الأكبر من أو تساوي بداية اليوم
          .order('timestamp', ascending: false);
          
      if (response.isNotEmpty && mounted) {
        setState(() {
          // نعكس القائمة لعرضها من الأقدم للأحدث في الرسم البياني
          _historicalData = List<Map<String, dynamic>>.from(response.reversed);
        });
        print("✅ Loaded ${response.length} readings for today.");
      }
    } catch (e) { 
      print('History Error: $e'); 
    }
  }

  Future<void> _loadDevicesState() async {
    try {
      final response = await _supabase.from('devices')
          .select()
          .eq('user_id', _userId!);
          
      if (response.isNotEmpty && mounted) {
        Map<String, dynamic> newState = {};
        for (var item in response) {
          newState[item['id']] = item;
        }
        setState(() => _devicesState = newState);
      }
    } catch (e) { print('Devices Error: $e'); }
  }

  // التحكم اليدوي
  Future<void> _controlDevice(String deviceId, bool newState, {int duration = 0}) async {
    setState(() {
      if (_devicesState[deviceId] != null) {
        _devicesState[deviceId]['is_on'] = newState;
        _devicesState[deviceId]['mode'] = 'manual'; 
      }
    });

    try {
      await _supabase.from('devices').update({
        'is_on': newState,
        'mode': 'manual', 
      })
      .eq('id', deviceId)
      .eq('user_id', _userId!);
    } catch (e) {
      _loadDevicesState(); 
    }
  }

  // الرجوع للوضع التلقائي
  Future<void> _setAutoMode(String deviceId) async {
    setState(() {
      if (_devicesState[deviceId] != null) {
        _devicesState[deviceId]['mode'] = 'auto'; 
      }
    });

    try {
      await _supabase.from('devices').update({'mode': 'auto'})
      .eq('id', deviceId)
      .eq('user_id', _userId!);
    } catch (e) {
      _loadDevicesState(); 
    }
  }

  // تحديث القائمة المحلية عند وصول بيانات جديدة
  void _updateHistoricalList(Map<String, dynamic> newData) {
    if (!mounted) return;
    setState(() {
      _historicalData.add(newData);
      // الاحتفاظ بحد أقصى 2000 نقطة في الذاكرة لضمان سلاسة التطبيق
      if (_historicalData.length > 2000) _historicalData.removeAt(0);
    });
  }

  void _setupRealtimeSubscription() {
    _supabase.channel('public:plant_data_$_userId').onPostgresChanges(
      event: PostgresChangeEvent.insert, 
      schema: 'public', 
      table: 'plant_data',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: _userId!),
      callback: (payload) {
        final newData = Map<String, dynamic>.from(payload.newRecord!);
        if (mounted) {
          setState(() {
            _currentData = newData;
            _updateHistoricalList(newData);
          });
        }
      },
    ).subscribe();

    _supabase.channel('public:devices_$_userId').onPostgresChanges(
      event: PostgresChangeEvent.update, 
      schema: 'public', 
      table: 'devices',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: _userId!),
      callback: (payload) {
        final updatedDevice = payload.newRecord!;
        if (mounted) {
          setState(() {
            _devicesState[updatedDevice['id']] = updatedDevice;
          });
        }
      },
    ).subscribe();
  }

  String _getSensorValue(String valueKey, String unit) {
    if (_currentData.isEmpty) return '0$unit';
    final value = _currentData[valueKey];
    if (value == null) return '0$unit';
    double numVal = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    
    int decimals = (valueKey == 'soil_ph' || valueKey == 'uv_index') ? 1 : (valueKey == 'soil_ec' ? 2 : 0);
    return '${numVal.toStringAsFixed(decimals)}$unit';
  }

  String _getPageTitle(bool isArabic) {
    List<String> titles = isArabic 
      ? ['الرئيسية', 'الحساسات', 'التحكم', 'طبيب النبات', 'عن التطبيق', 'التنبيهات', 'الإعدادات']
      : ['Dashboard', 'Sensors', 'Control', 'Plant Doctor', 'About Us', 'Notifications', 'Settings'];
    return _currentIndex < titles.length ? titles[_currentIndex] : 'FarmNet';
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(currentData: _currentData, currentTime: _currentTime, getSensorValue: _getSensorValue);
      case 1:
        return SensorsScreen(currentData: _currentData, historicalData: _historicalData, getSensorValue: _getSensorValue);
      case 2:
        return ControlScreen(devicesState: _devicesState, onControlDevice: _controlDevice, onSetAutoMode: _setAutoMode);
      case 3:
        return const PlantDoctorScreen();
      case 4:
        return AboutScreen();
      case 5:
        return NotificationsScreen(historicalData: _historicalData); 
      case 6:
        return const SettingsScreen();
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = languageNotifier.value;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        centerTitle: true,
        title: Text(_getPageTitle(isArabic), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      drawer: Sidebar(currentIndex: _currentIndex, onIndexChanged: (index) => setState(() => _currentIndex = index)),
      body: SafeArea(
        child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.accentColor)) : _buildCurrentScreen(),
      ),
    );
  }
}