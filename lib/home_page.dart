import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'api_service.dart';
import 'timetable_model.dart';
import 'find_teacher_page.dart';
import 'find_classroom_page.dart';
import 'student_timetable_page.dart';
import 'main.dart';
import 'profile_page.dart';
import 'emptyclassrooms_page.dart'; // CR uses this (Edit access)
import 'Events_page.dart';

// Class Representative Home Page Class
class HomePage extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final String? userName;
  final String? userEmail;
  final String? branch;
  final String? section;
  final String? semester;
  final String? profile;

  const HomePage({
    super.key,
    required this.universityName,
    this.isDark = false,
    this.onToggleTheme,
    this.userName,
    this.userEmail,
    this.branch,
    this.section,
    this.semester,
    this.profile,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _index = 0;
  late PageController _pageController;
  late String selectedDept;
  late String selectedSection;
  late String selectedSemester;
  late String userName;
  late String userEmail;
  late bool _isDark;

  // Timetable State for Next Class Card
  Timetable? _fullTimetable;
  bool _isLoadingTimetable = true;

  final List<String> eventImages = const [
    '[https://picsum.photos/1200/600?random=1](https://picsum.photos/1200/600?random=1)',
    '[https://picsum.photos/1200/600?random=2](https://picsum.photos/1200/600?random=2)',
    '[https://picsum.photos/1200/600?random=3](https://picsum.photos/1200/600?random=3)',
  ];

  // Slot start times (24h format) matches student_timetable_page
  final List<String> _slotStartTimes = [
    '09:00', '09:50', '10:50', '11:40', '12:30', '13:20', '14:10', '15:10', '16:00'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    // Initialize with data passed from Login/Main
    selectedDept = (widget.branch ?? 'EEE').toUpperCase();
    selectedSection = (widget.section ?? 'A').toUpperCase();
    selectedSemester = (widget.semester ?? '5');
    userName = widget.userName ?? 'CR Name';
    userEmail = widget.userEmail ?? 'cr@university.edu';
    _isDark = widget.isDark;

    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    try {
      // Use the CR's class details to fetch the timetable for the Dashboard card
      final timetable = await ApiService.getTimetable(
        selectedDept,
        selectedSemester,
        selectedSection,
      );
      if (mounted) {
        setState(() {
          _fullTimetable = timetable;
          _isLoadingTimetable = false;
        });
      }
    } catch (e) {
      print("Error loading home timetable: $e");
      if (mounted) setState(() => _isLoadingTimetable = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateUserName(String name) => setState(() => userName = name);
  void _updateUserEmail(String email) => setState(() => userEmail = email);

  // --- LOGIC TO FIND NEXT CLASS ---
  Map<String, dynamic>? _getNextClassInfo() {
    if (_fullTimetable == null) return null;

    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    int toMinutes(String time) {
      final p = time.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    int currentMinutes = now.hour * 60 + now.minute;
    int todayWeekdayIndex = now.weekday - 1; // Mon=0, Sun=6

    // 1. Check Today
    if (todayWeekdayIndex >= 0 && todayWeekdayIndex < 5) {
      String todayName = days[todayWeekdayIndex];
      final todayData = _fullTimetable!.grid.firstWhere(
            (d) => d.dayName == todayName,
        orElse: () => TimetableDay(dayName: '', slots: []),
      );

      for (int i = 0; i < _slotStartTimes.length; i++) {
        // If slot hasn't passed yet
        if (toMinutes(_slotStartTimes[i]) > currentMinutes) {
          if (i < todayData.slots.length) {
            final slot = todayData.slots[i];
            if (slot.courseCode.isNotEmpty) {
              return {
                'slot': slot,
                'time': _slotStartTimes[i],
                'day': 'Today'
              };
            }
          }
        }
      }
    }

    // 2. Check Tomorrow (or Monday if today is Fri/Sat/Sun)
    int nextDayIndex = (todayWeekdayIndex + 1) % 7;
    if (nextDayIndex > 4) nextDayIndex = 0;

    String nextDayName = days[nextDayIndex];
    final nextDayData = _fullTimetable!.grid.firstWhere(
          (d) => d.dayName == nextDayName,
      orElse: () => TimetableDay(dayName: '', slots: []),
    );

    for (int i = 0; i < nextDayData.slots.length; i++) {
      final slot = nextDayData.slots[i];
      if (slot.courseCode.isNotEmpty) {
        return {
          'slot': slot,
          'time': _slotStartTimes[i],
          'day': nextDayName
        };
      }
    }

    return null;
  }

  Widget _homePage(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 16),
        // Carousel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.95,
                    autoPlayInterval: const Duration(seconds: 3),
                  ),
                  items: eventImages.map((url) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(url, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // --- NEXT CLASS WIDGET ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildNextClassCard(scheme, isDark),
        ),

        const SizedBox(height: 24),

        // Announcements Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [scheme.primary, scheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Announcements",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Announcement Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              _buildAnnouncementCard(
                context,
                icon: Icons.campaign,
                title: "Tech Fest this weekend!",
                subtitle: "Don't miss the cultural night.",
                gradient: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
              ),
              const SizedBox(height: 10),
              _buildAnnouncementCard(
                context,
                icon: Icons.book,
                title: "Library open till 10 PM",
                subtitle: "Extended hours for exams.",
                gradient: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNextClassCard(ColorScheme scheme, bool isDark) {
    if (_isLoadingTimetable) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator()));
    }

    final nextClass = _getNextClassInfo();

    final Gradient bgGradient = isDark
        ? const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D47A1)])
        : const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]);

    if (nextClass == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: scheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: const Center(
          child: Text("No upcoming classes found.",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
      );
    }

    final TimetableSlot slot = nextClass['slot'];
    final String time = nextClass['time'];
    final String day = nextClass['day'];

    final String displayRoom =
    (slot.newRoom != null && slot.newRoom!.isNotEmpty)
        ? slot.newRoom!
        : (slot.room.isNotEmpty ? slot.room : "TBA");

    final bool isCancelled = slot.isCancelled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isCancelled
            ? LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade700])
            : bgGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isCancelled ? Colors.red : scheme.primary).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "$day @ $time",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isCancelled)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text("CANCELLED",
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            slot.courseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            slot.facultyName.isNotEmpty
                ? slot.facultyName
                : "Faculty not assigned",
            style:
            TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: Colors.white.withOpacity(0.9), size: 18),
              const SizedBox(width: 8),
              Text(
                "Room: $displayRoom",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              if (slot.newRoom != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text("UPDATED",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                )
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required List<Color> gradient,
      }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.universityName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            key: ValueKey('theme_toggle_$_isDark'),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(turns: animation, child: child);
              },
              child: Icon(
                _isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                key: ValueKey(_isDark),
              ),
            ),
            onPressed: () {
              setState(() {
                _isDark = !_isDark;
              });
              if (widget.onToggleTheme != null) {
                widget.onToggleTheme!(_isDark);
              }
            },
            tooltip: _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),

      drawer: Drawer(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A237E), const Color(0xFF283593)]
                      : [const Color(0xFFA4123F), const Color(0xFFD81B60)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(
                            "[https://i.pravatar.cc/150?img=3](https://i.pravatar.cc/150?img=3)",
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$selectedDept - $selectedSection',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: "Home",
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_search_rounded,
                    title: 'Find Teacher (Cabin/Room)',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FindTeacherPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.search_rounded,
                    title: "Find Friend Class Room",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FindClassRoomPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.schedule_rounded,
                    title: "Timetable",
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.event_rounded,
                    title: "Events",
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(2);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: "Settings",
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(4);
                    },
                  ),
                  const Divider(height: 20),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginPage(
                            isDark: _isDark,
                            onToggleTheme: widget.onToggleTheme ?? (bool v) {},
                          ),
                        ),
                            (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          _homePage(context),
          // FIXED: Pass parameters without using 'const' because variables are non-constant
          StudentTimetablePage(
            embedded: true,
            initialBranch: selectedDept,
            initialSemester: selectedSemester,
            initialSection: selectedSection,
            userRole: 'classrep',
          ),
          const EventsPage(),
          const EmptyClassroomsPage(),
          ProfilePage(
            userName: userName,
            userEmail: userEmail,
            dept: selectedDept,
            section: selectedSection,
            isDark: _isDark,
            onToggleTheme: (bool isDark) {
              setState(() => _isDark = isDark);
              if (widget.onToggleTheme != null) {
                widget.onToggleTheme!(isDark);
              }
            },
            onUpdateName: _updateUserName,
            onUpdateEmail: _updateUserEmail,
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goToPage,
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule_rounded),
              label: 'Timetable',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event_rounded),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room_rounded),
              label: 'Classrooms',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? scheme.error : scheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? scheme.error : scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}