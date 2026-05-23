import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _userId;
  Map<String, dynamic> _currentData = {};
  bool _isLoading = true;
  int _currentIndex = 0;
  DateTime _currentTime = DateTime.now();

  Timer? _clockTimer;
  Timer? _pollingTimer; // Timer جديد لجلب البيانات من الـ API

  Map<String, dynamic> _devicesState = {
    'water_pump': {'is_on': false, 'mode': 'auto'},
    'grow_lights': {'is_on': false, 'mode': 'auto'}
  };
  List<Map<String, dynamic>> _historicalData = [];

  @override
  void initState() {
    super.initState();
    _initUserAndData();
    _startClockTimer();
  }

  Future<void> _initUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? 'default_user';

    await _initializeApp();

    // بدء الـ Polling كل 5 ثواني لجلب البيانات الجديدة (كبديل للـ Realtime)
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadLatestData();
      _loadDevicesState();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait(
          [_loadLatestData(), _loadHistoricalData(), _loadDevicesState()]);
    } catch (e) {
      print('Error initializing: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLatestData() async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.serverBaseUrl}/api/latest-data/$_userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _currentData = data;
          });
          _updateHistoricalList(data);
        }
      }
    } catch (e) {
      print('Latest Data Fetch Error: $e');
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.serverBaseUrl}/api/history/$_userId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _historicalData = List<Map<String, dynamic>>.from(data.reversed);
          });
        }
      }
    } catch (e) {
      print('History Error: $e');
    }
  }

  Future<void> _loadDevicesState() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.serverBaseUrl}/api/devices/$_userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            // دمج البيانات المستلمة مع الـ state الحالي
            if (data.containsKey('water_pump'))
              _devicesState['water_pump'] = data['water_pump'];
            if (data.containsKey('grow_lights'))
              _devicesState['grow_lights'] = data['grow_lights'];
          });
        }
      }
    } catch (e) {
      print('Devices Error: $e');
    }
  }

  Future<void> _controlDevice(String deviceId, bool newState,
      {int duration = 0}) async {
    setState(() {
      if (_devicesState[deviceId] != null) {
        _devicesState[deviceId]['is_on'] = newState;
        _devicesState[deviceId]['mode'] = 'manual';
      }
    });
    try {
      await http.post(
          Uri.parse('${AppConfig.serverBaseUrl}/api/devices/control'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': _userId,
            'device_id': deviceId,
            'is_on': newState,
            'mode': 'manual'
          }));
    } catch (e) {
      _loadDevicesState(); // تراجع لو حصل مشكلة
    }
  }

  Future<void> _setAutoMode(String deviceId) async {
    setState(() {
      if (_devicesState[deviceId] != null) {
        _devicesState[deviceId]['mode'] = 'auto';
      }
    });
    try {
      await http.post(
          Uri.parse('${AppConfig.serverBaseUrl}/api/devices/control'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(
              {'user_id': _userId, 'device_id': deviceId, 'mode': 'auto'}));
    } catch (e) {
      _loadDevicesState();
    }
  }

  void _updateHistoricalList(Map<String, dynamic> newData) {
    if (!mounted) return;

    // منع التكرار لو البيانات مفيش فيها جديد
    if (_historicalData.isNotEmpty &&
        _historicalData.last['timestamp'] == newData['timestamp']) return;

    setState(() {
      _historicalData.add(newData);
      if (_historicalData.length > 2000) _historicalData.removeAt(0);
    });
  }

  String _getSensorValue(String valueKey, String unit) {
    if (_currentData.isEmpty) return '0$unit';
    final value = _currentData[valueKey];
    if (value == null) return '0$unit';
    double numVal = (value is num)
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0.0;
    int decimals = (valueKey == 'soil_ph' || valueKey == 'uv_index')
        ? 1
        : (valueKey == 'soil_ec' ? 2 : 0);
    return '${numVal.toStringAsFixed(decimals)}$unit';
  }

  String _getPageTitle(bool isArabic) {
    List<String> titles = isArabic
        ? [
            'الرئيسية',
            'الحساسات',
            'التحكم',
            'طبيب النبات',
            'عن التطبيق',
            'التنبيهات',
            'الإعدادات'
          ]
        : [
            'Dashboard',
            'Sensors',
            'Control',
            'Plant Doctor',
            'About Us',
            'Notifications',
            'Settings'
          ];
    return _currentIndex < titles.length ? titles[_currentIndex] : 'FarmNet';
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
            currentData: _currentData,
            currentTime: _currentTime,
            getSensorValue: _getSensorValue);
      case 1:
        return SensorsScreen(
            currentData: _currentData,
            historicalData: _historicalData,
            getSensorValue: _getSensorValue);
      case 2:
        return ControlScreen(
            devicesState: _devicesState,
            onControlDevice: _controlDevice,
            onSetAutoMode: _setAutoMode);
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
        iconTheme:
            IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        centerTitle: true,
        title: Text(_getPageTitle(isArabic),
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      drawer: Sidebar(
          currentIndex: _currentIndex,
          onIndexChanged: (index) => setState(() => _currentIndex = index)),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentColor))
            : _buildCurrentScreen(),
      ),
    );
  }
}
