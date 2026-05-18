import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plant_monitor/constants.dart';
import 'package:plant_monitor/home_page.dart';

class LoginScreen extends StatefulWidget {

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _isLoading = false;

  bool _rememberMe = false;

  // ===================================================
  // ================= SIGN IN =========================
  // ===================================================

  Future<void> _signIn() async {

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {

      _showError(
        'Please fill in all fields',
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {

      // ================= حفظ بيانات الدخول =================

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'remember_me',
        _rememberMe,
      );

      await prefs.setString(
        'user_email',
        _emailController.text.trim(),
      );

      // ================= انتقال للهوم =================

      if (mounted) {

        Navigator.of(context).pushReplacement(

          MaterialPageRoute(
            builder: (_) =>
                const HomePage(),
          ),
        );
      }

    } catch (e) {

      _showError(
        'Login Error: $e',
      );

    } finally {

      if (mounted) {

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ===================================================
  // ================= SHOW ERROR ======================
  // ===================================================

  void _showError(String message) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        backgroundColor: Colors.red,
      ),
    );
  }

  // ===================================================
  // ================= BUILD ===========================
  // ===================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          AppColors.backgroundColor,

      body: Center(

        child: SingleChildScrollView(

          padding:
              const EdgeInsets.all(24),

          child: Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              // ================= Logo =================

              Container(

                padding:
                    const EdgeInsets.all(20),

                decoration: BoxDecoration(

                  color:
                      AppColors.accentColor
                          .withOpacity(0.1),

                  shape: BoxShape.circle,
                ),

                child: const Icon(

                  Icons.eco,

                  size: 80,

                  color:
                      AppColors.accentColor,
                ),
              ),

              const SizedBox(height: 24),

              const Text(

                'Welcome Back!',

                style: TextStyle(

                  fontSize: 28,

                  fontWeight:
                      FontWeight.bold,

                  color:
                      AppColors.textColor,
                ),
              ),

              const SizedBox(height: 8),

              const Text(

                'Sign in to your farm dashboard',

                style: TextStyle(

                  color:
                      AppColors
                          .secondaryTextColor,
                ),
              ),

              const SizedBox(height: 40),

              // ================= Email =================

              TextField(

                controller:
                    _emailController,

                style: const TextStyle(

                  color: Colors.black,

                  fontSize: 16,
                ),

                decoration: InputDecoration(

                  labelText: 'Email',

                  labelStyle:
                      const TextStyle(
                    color: Colors.grey,
                  ),

                  prefixIcon: const Icon(

                    Icons.email_outlined,

                    color:
                        AppColors.accentColor,
                  ),

                  border: OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  enabledBorder:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    borderSide: BorderSide(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),

                  filled: true,

                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // ================= Password =================

              TextField(

                controller:
                    _passwordController,

                obscureText: true,

                style: const TextStyle(

                  color: Colors.black,

                  fontSize: 16,
                ),

                decoration: InputDecoration(

                  labelText: 'Password',

                  labelStyle:
                      const TextStyle(
                    color: Colors.grey,
                  ),

                  prefixIcon: const Icon(

                    Icons.lock_outline,

                    color:
                        AppColors.accentColor,
                  ),

                  border: OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  enabledBorder:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    borderSide: BorderSide(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),

                  filled: true,

                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // ================= Remember Me =================

              Row(

                children: [

                  Checkbox(

                    value: _rememberMe,

                    activeColor:
                        AppColors.accentColor,

                    onChanged: (val) {

                      setState(() {

                        _rememberMe =
                            val ?? false;
                      });
                    },
                  ),

                  const Text(

                    "Remember Me / تذكرني",

                    style: TextStyle(

                      color:
                          AppColors.textColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= Login Button =================

              SizedBox(

                width: double.infinity,

                height: 50,

                child: ElevatedButton(

                  onPressed:
                      _isLoading
                      ? null
                      : _signIn,

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        AppColors.accentColor,

                    foregroundColor:
                        Colors.white,

                    elevation: 2,

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child:
                      _isLoading

                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )

                      : const Text(

                          'Login',

                          style: TextStyle(

                            fontSize: 16,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}