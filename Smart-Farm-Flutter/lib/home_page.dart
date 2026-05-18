import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
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

  // ================= User ID =================

  // مؤقتًا ثابت لحد ما تعمل Authentication حقيقي
  String? _userId =
      "17b7dec9-b349-4a51-bf03-edb57fbf7793";

  // ================= App State =================

  Map<String, dynamic> _currentData = {};

  bool _isLoading = true;

  int _currentIndex = 0;

  DateTime _currentTime = DateTime.now();

  Timer? _clockTimer;

  Timer? _pollingTimer;

  // ================= Devices State =================

  Map<String, dynamic> _devicesState = {
    'water_pump': {
      'is_on': false,
      'mode': 'auto'
    },
    'grow_lights': {
      'is_on': false,
      'mode': 'auto'
    }
  };

  // ================= Historical Data =================

  List<Map<String, dynamic>> _historicalData = [];

  // ===================================================
  // ================= INIT STATE ======================
  // ===================================================

  @override
  void initState() {

    super.initState();

    _startClockTimer();

    _initializeApp();
  }

  // ===================================================
  // ================= DISPOSE =========================
  // ===================================================

  @override
  void dispose() {

    _clockTimer?.cancel();

    _pollingTimer?.cancel();

    super.dispose();
  }

  // ===================================================
  // ================= CLOCK TIMER =====================
  // ===================================================

  void _startClockTimer() {

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {

        if (mounted) {

          setState(() {
            _currentTime = DateTime.now();
          });
        }
      },
    );
  }

  // ===================================================
  // ================= INITIALIZE ======================
  // ===================================================

  Future<void> _initializeApp() async {

    try {

      await _loadLatestData();

      await Future.wait([
        _loadHistoricalData(),
        _loadDevicesState(),
      ]);

      _startPolling();

    } catch (e) {

      print("Initialization Error: $e");

      if (mounted) {

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ===================================================
  // ================= POLLING =========================
  // ===================================================

  void _startPolling() {

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) async {

        await _loadLatestData();

        await _loadDevicesState();
      },
    );
  }

  // ===================================================
  // ================= LOAD LATEST DATA ================
  // ===================================================

  Future<void> _loadLatestData() async {

    try {

      final response = await http.get(
        Uri.parse(
          '${AppConfig.serverBaseUrl}/api/latest-data/$_userId',
        ),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (mounted) {

          setState(() {

            _currentData =
                Map<String, dynamic>.from(data);

            _isLoading = false;
          });

          _updateHistoricalList(_currentData);
        }

      } else {

        if (mounted) {

          setState(() {
            _isLoading = false;
          });
        }
      }

    } catch (e) {

      print("Latest Data Error: $e");

      if (mounted) {

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ===================================================
  // ================= LOAD HISTORY ====================
  // ===================================================

  Future<void> _loadHistoricalData() async {

    try {

      final response = await http.get(
        Uri.parse(
          '${AppConfig.serverBaseUrl}/api/history/$_userId',
        ),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (mounted) {

          setState(() {

            _historicalData =
                List<Map<String, dynamic>>.from(data);
          });
        }
      }

    } catch (e) {

      print("History Error: $e");
    }
  }

  // ===================================================
  // ================= LOAD DEVICES ====================
  // ===================================================

  Future<void> _loadDevicesState() async {

    try {

      final response = await http.get(
        Uri.parse(
          '${AppConfig.serverBaseUrl}/api/devices/$_userId',
        ),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        Map<String, dynamic> newState = {};

        for (var item in data) {

          newState[item['id']] = item;
        }

        if (mounted) {

          setState(() {
            _devicesState = newState;
          });
        }
      }

    } catch (e) {

      print("Devices Error: $e");
    }
  }

  // ===================================================
  // ================= CONTROL DEVICE ==================
  // ===================================================

  Future<void> _controlDevice(
    String deviceId,
    bool newState,
    {
      int duration = 0,
    }
  ) async {

    try {

      final response = await http.post(
        Uri.parse(
          '${AppConfig.serverBaseUrl}/api/control',
        ),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'user_id': _userId,
          'device_id': deviceId,
          'is_on': newState,
          'mode': 'manual',
        }),
      );

      if (response.statusCode == 200) {

        await _loadDevicesState();

      } else {

        print("Control Error");
      }

    } catch (e) {

      print("Control Device Error: $e");
    }
  }

  // ===================================================
  // ================= AUTO MODE =======================
  // ===================================================

  Future<void> _setAutoMode(String deviceId) async {

    try {

      final response = await http.post(
        Uri.parse(
          '${AppConfig.serverBaseUrl}/api/control',
        ),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'user_id': _userId,
          'device_id': deviceId,
          'mode': 'auto',
        }),
      );

      if (response.statusCode == 200) {

        await _loadDevicesState();
      }

    } catch (e) {

      print("Auto Mode Error: $e");
    }
  }

  // ===================================================
  // ================= UPDATE HISTORY ==================
  // ===================================================

  void _updateHistoricalList(
    Map<String, dynamic> newData
  ) {

    if (!mounted) return;

    setState(() {

      _historicalData.add(newData);

      if (_historicalData.length > 2000) {

        _historicalData.removeAt(0);
      }
    });
  }

  // ===================================================
  // ================= SENSOR VALUE ====================
  // ===================================================

  String _getSensorValue(
    String valueKey,
    String unit,
  ) {

    if (_currentData.isEmpty) {

      return '0$unit';
    }

    final value = _currentData[valueKey];

    if (value == null) {

      return '0$unit';
    }

    double numVal =
        (value is num)
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0.0;

    int decimals =
        (valueKey == 'soil_ph' || valueKey == 'uv_index')
        ? 1
        : (valueKey == 'soil_ec' ? 2 : 0);

    return '${numVal.toStringAsFixed(decimals)}$unit';
  }

  // ===================================================
  // ================= PAGE TITLE ======================
  // ===================================================

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

    return _currentIndex < titles.length
      ? titles[_currentIndex]
      : 'FarmNet';
  }

  // ===================================================
  // ================= BUILD SCREEN ====================
  // ===================================================

  Widget _buildCurrentScreen() {

    switch (_currentIndex) {

      case 0:

        return DashboardScreen(
          currentData: _currentData,
          currentTime: _currentTime,
          getSensorValue: _getSensorValue,
        );

      case 1:

        return SensorsScreen(
          currentData: _currentData,
          historicalData: _historicalData,
          getSensorValue: _getSensorValue,
        );

      case 2:

        return ControlScreen(
          devicesState: _devicesState,
          onControlDevice: _controlDevice,
          onSetAutoMode: _setAutoMode,
        );

      case 3:

        return const PlantDoctorScreen();

      case 4:

        return AboutScreen();

      case 5:

        return NotificationsScreen(
          historicalData: _historicalData,
        );

      case 6:

        return const SettingsScreen();

      default:

        return const SettingsScreen();
    }
  }

  // ===================================================
  // ================= BUILD ===========================
  // ===================================================

  @override
  Widget build(BuildContext context) {

    final isArabic = languageNotifier.value;

    return Scaffold(

      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(

        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor,

        elevation: 0,

        iconTheme: IconThemeData(
          color:
              Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color,
        ),

        centerTitle: true,

        title: Text(

          _getPageTitle(isArabic),

          style: TextStyle(

            color:
                Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color,

            fontWeight: FontWeight.bold,

            fontSize: 18,
          ),
        ),
      ),

      drawer: Sidebar(
        currentIndex: _currentIndex,
        onIndexChanged: (index) {

          setState(() {
            _currentIndex = index;
          });
        },
      ),

      body: SafeArea(

        child: _isLoading

          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentColor,
              ),
            )

          : _buildCurrentScreen(),
      ),
    );
  }
}