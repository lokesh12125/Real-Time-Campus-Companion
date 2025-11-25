// lib/staff_homepage.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'emptyclassrooms_page.dart';
import 'api_service.dart'; // ✅ Import ApiService
import 'main.dart'; // ✅ Import main.dart to access LoginPage

void main() {
  runApp(const MyApp());
}

// ----------------------- APP -----------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

  void _toggleTheme(bool value) => setState(() => _isDark = value);

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      navigationBarTheme: const NavigationBarThemeData(
        height: 70,
        elevation: 2,
      ),
    );

    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      navigationBarTheme: const NavigationBarThemeData(
        height: 70,
        elevation: 2,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'University Staff Portal',
      theme: light,
      darkTheme: dark,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: StaffHome(
        universityName: 'Amrita Vishwa Vidyapeetham',
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

// ----------------------- STAFF HOME -----------------------
class StaffHome extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  final String? userName;
  final String? userEmail;
  final String? department;
  final String? cabin;
  final String? profilePhotoUrl;
  final String? userId; // ✅ Added userId field

  const StaffHome({
    super.key,
    required this.universityName,
    required this.isDark,
    required this.onToggleTheme,
    this.userName,
    this.userEmail,
    this.department,
    this.cabin,
    this.profilePhotoUrl,
    this.userId, // ✅ Added to constructor
  });

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _index = 0;
  late PageController _pageController;

  late String staffName;
  late String staffEmail;
  late String department;
  late String cabin;
  late String profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    
    staffName = widget.userName ?? 'Staff Member';
    staffEmail = widget.userEmail ?? 'staff@amrita.edu';
    department = widget.department ?? 'General';
    cabin = widget.cabin ?? 'N/A';
    profilePhotoUrl = widget.profilePhotoUrl ?? 'https://i.pravatar.cc/150?img=5';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() {
      _index = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // ✅ FIXED LOGOUT LOGIC
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Log Out?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dCtx); // Close Dialog
              
              // 1. Clear Token and User Data
              await ApiService.deleteToken();
              await ApiService.deleteUserProfile();

              if (!mounted) return;

              // 2. Navigate properly to LoginPage (removing history)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    isDark: widget.isDark,
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
                (route) => false,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.universityName),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
              ),
              onPressed: () => widget.onToggleTheme(!isDark),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF0B0B0B)]
                  : [const Color(0xFF06B6D4), const Color(0xFF06D6A0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          EmptyClassroomsPage(
            userBranch: department,
            userSection: cabin,
          ),

          ProfilePage(
            userName: staffName,
            userEmail: staffEmail,
            dept: department,
            section: cabin,
            isDark: isDark, 
            onToggleTheme: (v) => widget.onToggleTheme(v),
            
            // ✅ FIXED: UPDATE NAME IN DATABASE
            onUpdateName: (newName) async {
              // 1. Update Local UI
              setState(() => staffName = newName);
              
              // 2. Update Database
              if (widget.userId != null) {
                try {
                  await ApiService.updateUserById(
                    id: widget.userId!, 
                    name: newName
                  );
                  // Success handled silently
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save name to DB: $e'), 
                        backgroundColor: Colors.red
                      ),
                    );
                  }
                }
              } else {
                print("Error: User ID is null, cannot update database.");
              }
            },
            
            onUpdateEmail: (newEmail) => setState(() => staffEmail = newEmail),
            initialPhotoUrl: profilePhotoUrl,
            onChangePhoto: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change photo feature coming soon')),
              );
            },
            onLogout: _handleLogout,
            showAdminActions: true,
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Classrooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}