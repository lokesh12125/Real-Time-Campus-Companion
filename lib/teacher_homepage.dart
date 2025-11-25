import 'package:flutter/material.dart';
import 'dart:math' as math; 
import 'main.dart'; 
import 'student_timetable_page.dart'; 
import 'emptyclassrooms_page.dart'; 
import 'api_service.dart'; 
import 'timetable_model.dart'; 
import 'profile_page.dart'; // ✅ Imported ProfilePage

class TeacherHomePage extends StatelessWidget {
  final String universityName;
  final String userName;
  final String userEmail;
  final String? userId;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const TeacherHomePage({
    super.key,
    required this.universityName,
    required this.userName,
    required this.userEmail,
    this.userId,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return TeachersHome(
      universityName: universityName,
      isDark: isDark,
      onToggleTheme: onToggleTheme,
      userName: userName,
      userEmail: userEmail,
      userId: userId,
    );
  }
}

class TeachersHome extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  final String userName;
  final String userEmail;
  final String? userId;

  const TeachersHome({
    super.key,
    required this.universityName,
    required this.isDark,
    required this.onToggleTheme,
    required this.userName,
    required this.userEmail,
    this.userId,
  });

  @override
  State<TeachersHome> createState() => _TeachersHomeState();
}

class _TeachersHomeState extends State<TeachersHome>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Profile info
  late String teacherName;
  late String teacherEmail;
  String department = 'CSE';
  String cabin = 'Block A - 305';
  // Default image fallback
  String profileImage = 'https://i.pravatar.cc/150?img=5'; 
  String? _userId; 

  // Local state
  late bool _localIsDark;
  bool _isAvailable = true; // Default true, will update from DB

  // --- Dynamic Timetable State ---
  bool _isTimetableLoading = true;
  List<TimetableDay> _timetableGrid = [];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  // --- ANIMATION CONTROLLERS ---
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _pulseController;
  late Animation<double> _headerScale;
  late Animation<double> _headerFade;
  late Animation<double> _pulseAnimation;
  late List<Animation<double>> _cardSlides;

  List<Color> get _palette => [
    const Color(0xFF0D6EFD), 
    const Color(0xFF20C997), 
    const Color(0xFFFFA927), 
    const Color(0xFF8A63D2), 
    const Color(0xFFEF476F), 
  ];

  Color _paletteColor(int index, {double opacity = 1.0}) {
    final base = _palette[index % _palette.length];
    return base.withOpacity(opacity);
  }

  LinearGradient get _headerGradient => _localIsDark
      ? const LinearGradient(
    colors: [Color(0xFF1F1F1F), Color(0xFF121212)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  )
      : const LinearGradient(
    colors: [Color(0xFF0D6EFD), Color(0xFF20C997)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final List<Map<String, String>> slots = [
    {'no': '1', 'time': '09:00'},
    {'no': '2', 'time': '09:50'},
    {'no': '3', 'time': '10:50'},
    {'no': '4', 'time': '11:40'},
    {'no': '5', 'time': '12:30'},
    {'no': '6', 'time': '13:20'},
    {'no': '7', 'time': '14:10'},
    {'no': '8', 'time': '15:10'},
    {'no': '9', 'time': '16:00'},
  ];

  Map<String, List<Map<String, String>>> teacherTimetable = {
    'Mon': [], 'Tue': [], 'Wed': [], 'Thu': [], 'Fri': []
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    teacherName = widget.userName.isNotEmpty ? widget.userName : 'Dr. Sharma';
    teacherEmail = widget.userEmail.isNotEmpty ? widget.userEmail : 'dr.sharma@university.edu';
    _localIsDark = widget.isDark;
    
    // Initialize User ID from widget if available
    if (widget.userId != null) {
      _userId = widget.userId;
    }
    
    // Load Data
    _loadUserData();
    _loadTimetableData();

    // --- INITIALIZE ANIMATIONS ---
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _cardsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _headerScale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeIn));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _cardSlides = List.generate(6, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardsController, curve: Interval(i * 0.1, 0.5 + (i * 0.1), curve: Curves.easeOutCubic)));
    });

    _headerController.forward();
    _cardsController.forward();
  }

  // Updated: Fetch from DB to get real status
  Future<void> _loadUserData() async {
    try {
      // 1. Read basic info from local storage
      final userProfile = await ApiService.readUserProfile();
      
      if (userProfile != null) {
        String? idToUse = _userId ?? userProfile['_id'] ?? userProfile['id'];
        
        if (idToUse != null) {
          // 2. Fetch FRESH data from API
          try {
            final freshData = await ApiService.getUserById(idToUse);
            if (mounted) {
              setState(() {
                _userId = idToUse;
                // Update availability from DB
                if (freshData.containsKey('availability')) {
                  _isAvailable = freshData['availability'] == true;
                }
                if (freshData['cabinRoom'] != null) {
                  cabin = freshData['cabinRoom'];
                }
                // ✅ Fetch profile image from DB
                if (freshData['profile'] != null && freshData['profile']['url'] != null) {
                  profileImage = freshData['profile']['url'];
                }
                // Sync name if changed elsewhere
                if (freshData['name'] != null) {
                  teacherName = freshData['name'];
                }
              });
            }
          } catch (e) {
            print("Failed to fetch fresh user data: $e");
            // Fallback to local storage if API fails
            if (mounted) {
              setState(() {
                _userId = idToUse;
                if (userProfile['cabinRoom'] != null) cabin = userProfile['cabinRoom'];
                if (userProfile.containsKey('availability')) {
                   _isAvailable = userProfile['availability'] == true;
                }
                if (userProfile['profile'] != null && userProfile['profile']['url'] != null) {
                   profileImage = userProfile['profile']['url'];
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }

  Future<void> _loadTimetableData() async {
    try {
      final grid = await ApiService.getTeacherTimetable();
      if (mounted) {
        setState(() {
          _timetableGrid = grid;
          _isTimetableLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTimetableLoading = false);
      }
    }
  }

  Future<void> _updateSlot(String contextStr, String day, int index, bool isCancelled, String? newRoom) async {
    try {
      final parts = contextStr.split(' ');
      if (parts.length < 3) return;

      await ApiService.updateSlot(
        branch: parts[0],
        semester: parts[1],
        section: parts[2],
        dayName: day,
        slotIndex: index,
        isCancelled: isCancelled,
        newRoom: newRoom,
      );

      Navigator.pop(context);
      _loadTimetableData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!'), backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _updateAvailability(bool val) async {
    setState(() => _isAvailable = val);
    
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID not found. Relogin required.'), backgroundColor: Colors.red));
      return;
    }

    try {
      await ApiService.updateUserById(id: _userId!, availability: val);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? 'Marked Available' : 'Marked Busy'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() => _isAvailable = !val);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSlotDetails(TimetableSlot slot, String day, int index) {
    final roomCtrl = TextEditingController(text: slot.newRoom ?? slot.room);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class: ${slot.displayContext}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 5),
            Text(slot.courseName, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 15),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cancel Class'),
              value: slot.isCancelled,
              activeColor: Colors.red,
              onChanged: (val) => _updateSlot(slot.displayContext, day, index, val, null),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(labelText: 'Change Room', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => _updateSlot(slot.displayContext, day, index, slot.isCancelled, roomCtrl.text),
                  child: const Text('Update'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ LOGOUT HANDLER
  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => LoginPage(
        isDark: _localIsDark, 
        onToggleTheme: widget.onToggleTheme
      )), 
      (r) => false
    );
  }

  @override
  void didUpdateWidget(covariant TeachersHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      setState(() => _localIsDark = widget.isDark);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headerController.dispose();
    _cardsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    if (index == 3) {
      _headerController.reset();
      _cardsController.reset();
      _headerController.forward();
      _cardsController.forward();
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(decoration: BoxDecoration(gradient: _headerGradient)),
      title: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu, color: Colors.white, size: 26), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          const SizedBox(width: 8),
          const Expanded(child: Center(child: Text('Teacher Dashboard', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18)))),
          
          // ✅ FIXED THEME TOGGLE ICON LOGIC
          IconButton(
            // If Dark Mode is ON (_localIsDark == true) -> Show Sun (to switch to Light)
            // If Light Mode is ON (_localIsDark == false) -> Show Moon (to switch to Dark)
            icon: Icon(
              _localIsDark ? Icons.wb_sunny_rounded : Icons.nightlight_round, 
              color: Colors.white, 
              size: 26
            ),
            onPressed: () {
              setState(() => _localIsDark = !_localIsDark);
              widget.onToggleTheme(_localIsDark);
            },
            tooltip: _localIsDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Drawer _buildDrawer() {
    Widget menuItem({required int index, required IconData icon, required String label}) {
      final color = _paletteColor(index);
      final tileBg = _currentIndex == index ? _paletteColor(index, opacity: _localIsDark ? 0.18 : 0.12) : Colors.transparent;
      final iconColor = _localIsDark ? Colors.white : color;
      final textColor = _localIsDark ? Colors.white : Colors.black87;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
        child: Container(
          decoration: BoxDecoration(color: tileBg, borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Container(width: 6, height: double.infinity, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
            title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
            trailing: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: _localIsDark ? const Color(0xFF1F1F1F) : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _goToPage(index);
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: _localIsDark ? Colors.grey.shade900 : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(gradient: _headerGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 28, backgroundImage: NetworkImage(profileImage)),
                const SizedBox(height: 8),
                Text(teacherName, style: const TextStyle(fontSize: 18, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Faculty Member', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          menuItem(index: 0, icon: Icons.home, label: 'Home'),
          menuItem(index: 2, icon: Icons.meeting_room, label: 'Classrooms'),
          menuItem(index: 3, icon: Icons.person, label: 'Profile'),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(color: _localIsDark ? Colors.red.withOpacity(0.08) : Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Container(width: 6, height: double.infinity, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6))),
                  title: Text('Logout', style: TextStyle(color: _localIsDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                  trailing: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: _localIsDark ? const Color(0xFF1F1F1F) : Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.logout, color: _localIsDark ? Colors.white : Colors.redAccent, size: 18),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      backgroundColor: _localIsDark ? const Color(0xFF121212) : Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _buildHome(),
          const StudentTimetablePage(userRole: 'teacher'),
          EmptyClassroomsPage(userBranch: department, userSection: 'A'),
          
          // ✅ REPLACED LOCAL PROFILE WITH IMPORTED ProfilePage
          ProfilePage(
            userName: teacherName,
            userEmail: teacherEmail,
            dept: department,
            section: cabin,
            isDark: _localIsDark,
            onToggleTheme: (value) {
              setState(() => _localIsDark = value);
              widget.onToggleTheme(value);
            },
            initialPhotoUrl: profileImage, // ✅ Passed the profile image here
            
            // Logic to update name locally + DB
            onUpdateName: (newName) async {
              setState(() => teacherName = newName);
              if (_userId != null) {
                try {
                  await ApiService.updateUserById(id: _userId!, name: newName);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update name: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            // Logic to update email locally
            onUpdateEmail: (newEmail) => setState(() => teacherEmail = newEmail),
            
            onLogout: _handleLogout,
            showAdminActions: true, // Enable editing for teacher
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _localIsDark ? Colors.grey.shade900.withOpacity(0.92) : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (i) => _goToPage(i),
          selectedItemColor: _localIsDark ? Colors.white : Colors.black87,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          showSelectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home, size: 24), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month, size: 24), label: 'Student TT'),
            BottomNavigationBarItem(icon: Icon(Icons.meeting_room, size: 24), label: 'Classrooms'),
            BottomNavigationBarItem(icon: Icon(Icons.person, size: 24), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // --- HOME WIDGET ---
  Widget _buildHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: _headerGradient,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Use profileImage here as well for consistency on home screen
                  CircleAvatar(
                    radius: 32, 
                    backgroundColor: Colors.white24, 
                    backgroundImage: NetworkImage(profileImage),
                    child: profileImage.isEmpty ? const Icon(Icons.school, size: 32, color: Colors.white) : null
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 14)),
                        Text(teacherName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('$department • $cabin', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // CABIN STATUS CARD with API Call
                CabinStatusCard(
                  isAvailable: _isAvailable,
                  onChanged: (val) => _updateAvailability(val),
                ),
                const SizedBox(height: 12),
                NextClassCard(timetable: teacherTimetable, slots: slots),
                const SizedBox(height: 24),
                Text('Weekly Timetable', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _isTimetableLoading ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())) : _timetableGrid.isEmpty ? const Center(child: Text('No timetable data available')) : _buildTimetableGrid(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableGrid() {
    final Map<String, List<TimetableSlot>> gridMap = {};
    for (var d in _timetableGrid) {
      gridMap[d.dayName] = d.slots;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 80),
              ...slots.map((s) => Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: _localIsDark ? Colors.white12 : Colors.black12),
                  borderRadius: BorderRadius.circular(6),
                  color: _localIsDark ? const Color(0xFF252525) : Colors.white,
                ),
                child: Column(
                  children: [
                    Text(s['time']!, style: TextStyle(fontSize: 11, color: _localIsDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 4),
                    Text('(${s['no']})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _localIsDark ? Colors.white : Colors.black)),
                  ],
                ),
              )),
            ],
          ),
          ..._days.map((day) {
            final List<TimetableSlot> daySlots = gridMap[day] ?? List.generate(9, (_) => TimetableSlot());
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80, height: 100,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _localIsDark ? const Color(0xFF252525) : Colors.grey.shade100,
                    border: Border.all(color: _localIsDark ? Colors.white12 : Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: _localIsDark ? Colors.white : Colors.black87)),
                ),
                ...List.generate(9, (index) {
                  final slot = daySlots.length > index ? daySlots[index] : TimetableSlot();
                  final hasClass = slot.courseCode.isNotEmpty;
                  Color bg = _localIsDark ? Colors.transparent : Colors.white;
                  if (hasClass) bg = _localIsDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50;
                  if (slot.isCancelled) bg = _localIsDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50;
                  final borderColor = _localIsDark ? Colors.white12 : Colors.black12;

                  return GestureDetector(
                    onTap: hasClass ? () => _showSlotDetails(slot, day, index) : null,
                    child: Container(
                      width: 120, height: 100,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: bg, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasClass) ...[
                            Text(slot.displayContext, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _localIsDark ? Colors.blue.shade200 : Colors.blue.shade800)),
                            const SizedBox(height: 4),
                            Text(slot.courseCode, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _localIsDark ? Colors.white : Colors.black87)),
                            if (slot.isCancelled) ...[const SizedBox(height: 4), const Text('CANCELLED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))],
                            if (slot.newRoom != null) ...[const SizedBox(height: 4), Text(slot.newRoom!, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))]
                          ] else Text('-', style: TextStyle(color: _localIsDark ? Colors.white24 : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class CabinStatusCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;
  const CabinStatusCard({super.key, required this.isAvailable, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isAvailable ? const LinearGradient(colors: [Color(0xFF27E08D), Color(0xFF118B4A)]) : const LinearGradient(colors: [Color(0xFFEF476F), Color(0xFFD32F2F)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(isAvailable ? Icons.check_circle : Icons.do_not_disturb_on, color: Colors.white)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Cabin Status", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600)),
          Text(isAvailable ? "Available" : "Not Available", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ])),
        Switch(value: isAvailable, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: Colors.white24, inactiveThumbColor: Colors.white, inactiveTrackColor: Colors.white24),
      ]),
    );
  }
}

class NextClassCard extends StatelessWidget {
  final Map<String, List<Map<String, String>>> timetable;
  final List<Map<String, String>> slots;
  const NextClassCard({super.key, required this.timetable, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0B57D0), Color(0xFF0646A6)]), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))]),
      child: Row(children: [
        CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: const Icon(Icons.school, color: Colors.white, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('UPCOMING CLASS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 4),
          const Text('Check Timetable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ])),
      ]),
    );
  }
}