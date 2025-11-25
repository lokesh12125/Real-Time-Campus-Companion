// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'api_service.dart'; // Using ApiService for login
import 'teacher_homepage.dart';
import 'admin_homepage.dart';
import 'staff_homepage.dart';
import 'student_homepage.dart';
import 'forgot_password_page.dart';

const maroonColor = Color(0xFFA4123F);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RootApp());
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool _isDark = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('theme_dark') ?? false;
    setState(() {
      _isDark = saved;
      _loading = false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', value);
    setState(() => _isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: LoginPage(
        onToggleTheme: _toggleTheme,
        isDark: _isDark,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const LoginPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _loading = false;

  // Helper method to create floating orbs
  List<Widget> _buildFloatingOrbs() {
    return [
      Positioned(
        top: -50,
        left: -50,
        child: _FloatingOrb(size: 200, color: const Color(0xFFD4AF37).withOpacity(0.1)),
      ),
      Positioned(
        top: 100,
        right: -30,
        child: _FloatingOrb(size: 150, color: const Color(0xFFA4123F).withOpacity(0.2)),
      ),
      Positioned(
        bottom: -80,
        right: 50,
        child: _FloatingOrb(size: 250, color: const Color(0xFFD4AF37).withOpacity(0.15)),
      ),
      Positioned(
        bottom: 100,
        left: -40,
        child: _FloatingOrb(size: 180, color: Colors.white.withOpacity(0.05)),
      ),
    ];
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Use ApiService.login directly
      final res = await ApiService.login(email, password);
      
      // If successful (no exception thrown)
      final user = res['user'] as Map<String, dynamic>? ?? {};
      
      // 1. Get user role and normalize it
      final rawRole = (user['role'] as String?)?.trim().toLowerCase() ?? '';
      final role = rawRole.isEmpty ? 'student' : rawRole;

      // 2. Extract Common user info
      final userName = user['name'] ?? user['email'] ?? 'User';
      final userEmail = user['email'] ?? '';
      final branch = user['branch'] ?? 'N/A'; 
      final section = user['section'] ?? 'N/A';
      final semester = user['semester'];
      
      // 3. Extract User ID (Critical for Teacher Update)
      final userId = user['id'] ?? user['_id'];

      // 4. Extract Profile Image
      final String? profile = (user['profile'] != null && user['profile'].toString().isNotEmpty)
          ? user['profile'].toString()
          : null;

      Widget targetPage;

      if (role == 'teacher') {
        targetPage = TeacherHomePage(
          universityName: "Amrita Vishwa Vidyapeetham — Teacher",
          userName: userName,
          userEmail: userEmail,
          userId: userId, // ✅ Passed ID here!
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      } else if (role == 'staff') {
        targetPage = StaffHomePage(
          universityName: "Amrita Vishwa Vidyapeetham — Staff",
          userName: userName,
          userEmail: userEmail,
          profile: profile,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      } else if (role == 'admin') {
        targetPage = AdminHomePage(
          universityName: "Amrita Vishwa Vidyapeetham — Admin",
          userName: userName,
          userEmail: userEmail,
          profile: profile,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      } else if (role == 'classrep') {
        targetPage = HomePage( 
          universityName: _getUniversityNameForRole(role),
          userName: userName,
          userEmail: userEmail,
          profile: profile,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          branch: branch,
          section: section,
          semester: semester,
        );
      } else {
        // Student
        targetPage = StudentHomePage(
          universityName: _getUniversityNameForRole(role),
          userName: userName,
          userEmail: userEmail,
          profile: profile, 
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          branch: branch,
          section: section,
          semester: semester,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetPage),
        );
      }
    } catch (e) {
      if (mounted) {
        // Clean up exception message for UI
        final msg = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getUniversityNameForRole(String role) {
    switch (role) {
      case 'admin':
        return "Amrita Vishwa Vidyapeetham — Admin";
      case 'classrep':
      case 'class_rep':
      case 'cr':
        return "Amrita Vishwa Vidyapeetham — CR";
      case 'staff':
        return "Amrita Vishwa Vidyapeetham — Staff";
      default:
        return "Amrita Vishwa Vidyapeetham";
    }
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFFA4123F);
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a0a14),
              maroonColor,
              const Color(0xFF5a1035),
              maroonColor.withOpacity(0.8),
              const Color(0xFF2d0a1f),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated flowing orbs
            ..._buildFloatingOrbs(),

            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // College Logo
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/Untitled design.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.school,
                              size: 100,
                              color: goldColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Welcome Text
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: maroonColor.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Sign in to continue",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Glassmorphic Login Card
                        Container(
                          constraints: const BoxConstraints(maxWidth: 450),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Email Field
                                      TextFormField(
                                        controller: _emailController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: "Email",
                                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                          prefixIcon: Icon(Icons.email_outlined, color: goldColor),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.1),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide(
                                              color: goldColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        validator: (value) => value!.isEmpty ? "Enter email" : null,
                                      ),

                                      const SizedBox(height: 20),

                                      // Password Field
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: "Password",
                                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                          prefixIcon: Icon(Icons.lock_outline, color: goldColor),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.1),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide(
                                              color: goldColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        validator: (value) => value!.isEmpty ? "Enter password" : null,
                                      ),

                                      const SizedBox(height: 30),

                                      // Login Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _loading ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: maroonColor,
                                            foregroundColor: Colors.white,
                                            elevation: 8,
                                            shadowColor: maroonColor.withOpacity(0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                          ),
                                          child: _loading
                                              ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                              : const Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                          );
                                        },
                                        child: const Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated floating orb widget
class _FloatingOrb extends StatefulWidget {
  final double size;
  final Color color;

  const _FloatingOrb({required this.size, required this.color});

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            20 * _controller.value,
            30 * (1 - _controller.value),
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color,
                  widget.color.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}