// lib/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart'; // Required for token and baseUrl

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String dept;
  final String section;
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final ValueChanged<String>? onUpdateName;
  final ValueChanged<String>? onUpdateEmail;
  final String? initialPhotoUrl;
  final String? userId; // ✅ Added userId here
  final VoidCallback? onChangePhoto;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogout;
  final bool showAdminActions;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.dept,
    required this.section,
    this.isDark = false,
    this.onToggleTheme,
    this.onUpdateName,
    this.onUpdateEmail,
    this.initialPhotoUrl,
    this.userId, // ✅ Added to constructor
    this.onChangePhoto,
    this.onChangePassword,
    this.onLogout,
    this.showAdminActions = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late String _name;
  late String _email;
  late bool _localIsDark;
  late String? _profileImage;

  // Animations
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _pulseController;
  late AnimationController _avatarRotateController;
  late Animation<double> _headerScale;
  late Animation<double> _headerFade;
  late Animation<double> _pulseAnimation;
  late Animation<double> _avatarRotate;
  late List<Animation<double>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _name = widget.userName;
    _email = widget.userEmail;
    _localIsDark = widget.isDark;
    _profileImage = widget.initialPhotoUrl;

    // Fetch latest data from backend to ensure image is correct
    _fetchLatestProfileData();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _avatarRotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    )..repeat();

    _headerScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );

    _headerFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeIn));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _avatarRotate = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _avatarRotateController, curve: Curves.linear),
    );

    _cardSlides = List.generate(5, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(
            i * 0.10,
            0.4 + (i * 0.12),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _headerController.forward();
    _cardsController.forward();
  }

  /// Fetch latest user details from backend to ensure Profile Image is up to date
  Future<void> _fetchLatestProfileData() async {
    try {
      final profile = await ApiService.readUserProfile();
      if (profile != null) {
        final id = profile['_id'] ?? profile['id'];
        if (id != null) {
          final userData = await ApiService.getUserById(id);
          if (mounted) {
            setState(() {
              _name = userData['name'] ?? _name;
              _email = userData['email'] ?? _email;
              // Safely extract profile URL
              if (userData['profile'] != null && userData['profile']['url'] != null) {
                _profileImage = userData['profile']['url'];
              }
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching latest profile data: $e");
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _pulseController.dispose();
    _avatarRotateController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      setState(() => _localIsDark = widget.isDark);
    }
    // Only update if parent explicitly passes a new non-null url, 
    // otherwise keep the one we might have fetched from backend.
    if (oldWidget.initialPhotoUrl != widget.initialPhotoUrl && widget.initialPhotoUrl != null) {
      setState(() => _profileImage = widget.initialPhotoUrl);
    }
  }

  /// ✅ Safe Image Provider to handle Network vs Local File
  ImageProvider? _getSafeImageProvider(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (e) {
      // ignore error
    }
    return null; // Fallback to child icon
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildDialog(
        title: 'Edit Name',
        icon: Icons.edit_rounded,
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            prefixIcon: const Icon(Icons.person_rounded),
            filled: true,
          ),
        ),
      ),
    );

    if (result == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _name = ctrl.text.trim());
      widget.onUpdateName?.call(_name);
      _showSnackBar('Name updated successfully');
    }
  }

  // Enhanced Change Password with Backend Integration
  Future<void> _changePassword() async {
    if (widget.onChangePassword != null) {
      widget.onChangePassword!();
      return;
    }

    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF093FB).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: currentPasswordCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.key_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Min 6 chars',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Change Password'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final currentPass = currentPasswordCtrl.text.trim();
    final newPass = newPasswordCtrl.text.trim();
    final confirmPass = confirmPasswordCtrl.text.trim();

    if (currentPass.isEmpty) {
      _showSnackBar('Please enter current password', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    await _callChangePasswordAPI(currentPass, newPass);
  }

  Future<void> _callChangePasswordAPI(String currentPassword, String newPassword) async {
    // Use ApiService.baseUrl for consistency
    final uri = Uri.parse('${ApiService.baseUrl}/api/user/change-password');

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Updating password...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );

    try {
      final token = await ApiService.readToken();
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': _email, 
          'currentPassword': currentPassword, 
          'newPassword': newPassword
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar('✓ Password changed successfully!');
      } else {
        String errorMsg = responseBody['error'] ?? responseBody['message'] ?? 'Failed to change password';
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showSnackBar('Connection Error: $e', isError: true);
    }
  }

  void _changeProfileImage() {
    // Logic to change profile image can be implemented here using ImagePicker and ApiService
    _showSnackBar('Feature coming soon!');
  }

  Future<void> _logoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Log Out?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to sign out of this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (result == true) {
      _showSnackBar('Logged out successfully');
      widget.onLogout?.call();
    }
  }

  Widget _buildDialog({required String title, required IconData icon, required Widget content}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: content,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
      ],
    );
  }

  Widget _buildCompactHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageProvider = _getSafeImageProvider(_profileImage);

    return FadeTransition(
      opacity: _headerFade,
      child: ScaleTransition(
        scale: _headerScale,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A237E).withOpacity(0.95), const Color(0xFF4A148C).withOpacity(0.9)]
                  : [const Color(0xFF00BCD4).withOpacity(0.95), const Color(0xFF0097A7).withOpacity(0.9)],
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF4A148C) : Colors.cyan).withOpacity(0.5),
                blurRadius: 24, spreadRadius: -5, offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _CompactPatternPainter(isDark: isDark))),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 95, height: 95,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.0)],
                                ),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _avatarRotate,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _avatarRotate.value,
                                child: CustomPaint(size: const Size(95, 95), painter: _EnhancedRingPainter(isDark: isDark)),
                              );
                            },
                          ),
                          Hero(
                            tag: 'profile_image',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                              ),
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.white24,
                                backgroundImage: imageProvider,
                                child: imageProvider == null 
                                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ),
                          if (widget.showAdminActions)
                            Positioned(
                              bottom: 0, right: 0,
                              child: GestureDetector(
                                onTap: widget.onChangePhoto ?? _changeProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFF093FB), Color(0xFFF5576C)]),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [BoxShadow(color: const Color(0xFFF093FB).withOpacity(0.6), blurRadius: 12, offset: const Offset(0, 4))],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5, shadows: [Shadow(blurRadius: 12, color: Colors.black38, offset: Offset(0, 4))]),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4), 
                            
                            // --- REMOVED DEPARTMENT ROW (As Requested) ---
                            /*
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.35), shape: BoxShape.circle),
                                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text('${widget.dept} - ${widget.section}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.4), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            */
                            // ---------------------------------------------

                            // Email Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2), 
                                borderRadius: BorderRadius.circular(14)
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.email_rounded, color: Colors.white, size: 15),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(_email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildCompactCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required int index, List<Color>? gradientColors}) {
    final cs = Theme.of(context).colorScheme;
    final gradient = gradientColors ?? [cs.primary, cs.secondary];

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(_cardSlides[index]),
      child: FadeTransition(
        opacity: _cardSlides[index],
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.1), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))]),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface, letterSpacing: 0.2)),
                          const SizedBox(height: 4),
                          Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: gradient.first.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(Icons.arrow_forward_ios_rounded, color: gradient.first, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(int index) {
    final cs = Theme.of(context).colorScheme;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(_cardSlides[index]),
      child: FadeTransition(
        opacity: _cardSlides[index],
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.1), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Icon(_localIsDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface, letterSpacing: 0.2)),
                      const SizedBox(height: 4),
                      Text(_localIsDark ? 'Dark mode active' : 'Light mode active', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 1.1,
                  child: Switch.adaptive(
                    value: _localIsDark,
                    onChanged: (value) {
                      setState(() => _localIsDark = value);
                      widget.onToggleTheme?.call(value);
                    },
                    activeColor: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 8),
        _buildCompactHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 24,
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [cs.primary, cs.secondary]), borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 12),
              Text('Account Settings', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: cs.onSurface, letterSpacing: 0.4)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // 1. Edit Name Card
              _buildCompactCard(
                icon: Icons.person_rounded, 
                title: 'Edit Name', 
                subtitle: 'Update your display name', 
                onTap: _editName, 
                index: 0, 
                gradientColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)]
              ),
              
              // 2. Change Password Card
              _buildCompactCard(
                icon: Icons.lock_reset_rounded, 
                title: 'Change Password', 
                subtitle: 'Update your account password', 
                onTap: _changePassword, 
                index: 1, 
                gradientColors: [const Color(0xFFF093FB), const Color(0xFFF5576C)]
              ),
              
              // 3. Theme Toggle Card
              _buildThemeToggle(2),
              
              // 4. Logout Card
              if (widget.showAdminActions) ...[
                _buildCompactCard(
                  icon: Icons.logout_rounded, 
                  title: 'Log Out', 
                  subtitle: 'Sign out from your account', 
                  onTap: widget.onLogout ?? _logoutDialog, 
                  index: 3, 
                  gradientColors: [const Color(0xFFFA709A), const Color(0xFFFEE140)]
                ),
              ] else ...[
                // Ensure Logout is available for all users (like students) if desired
                _buildCompactCard(
                  icon: Icons.logout_rounded, 
                  title: 'Log Out', 
                  subtitle: 'Sign out from your account', 
                  onTap: widget.onLogout ?? _logoutDialog, 
                  index: 3, 
                  gradientColors: [const Color(0xFFFA709A), const Color(0xFFFEE140)]
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// Enhanced ring painter
class _EnhancedRingPainter extends CustomPainter {
  final bool isDark;
  _EnhancedRingPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final glowPaint = Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawCircle(center, radius, glowPaint);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: isDark ? [Colors.white, const Color(0xFF64B5F6), const Color(0xFFBA68C8), Colors.white] : [Colors.white, const Color(0xFF26C6DA), const Color(0xFF42A5F5), Colors.white],
      stops: const [0.0, 0.33, 0.66, 1.0],
    );
    final gradientPaint = Paint()..shader = gradient.createShader(rect)..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, gradientPaint);
  }
  @override
  bool shouldRepaint(_EnhancedRingPainter oldDelegate) => false;
}

// Enhanced pattern painter
class _CompactPatternPainter extends CustomPainter {
  final bool isDark;
  _CompactPatternPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.15 + i * 0.18);
      final y = size.height * 0.25;
      final radius = 35.0 - (i * 6);
      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
    final linePaint = Paint()..color = Colors.white.withOpacity(0.04)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (var i = 0; i < 7; i++) {
      final x = i * (size.width / 7);
      canvas.drawLine(Offset(x, 0), Offset(x + size.height * 0.4, size.height), linePaint);
    }
    final wavePaint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final path = Path();
    path.moveTo(0, size.height * 0.65);
    for (var i = 0; i <= 5; i++) {
      final x = (size.width / 5) * i;
      final y = size.height * 0.65 + (i.isEven ? -20 : 20);
      if (i == 0) path.lineTo(x, y); else {
        final prevX = (size.width / 5) * (i - 1);
        final prevY = size.height * 0.65 + ((i - 1).isEven ? -20 : 20);
        final controlX = (prevX + x) / 2;
        final controlY = (prevY + y) / 2;
        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }
    canvas.drawPath(path, wavePaint);
    final radialPaint = Paint()..shader = RadialGradient(center: const Alignment(0.2, -0.6), radius: 1.3, colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), radialPaint);
  }
  @override
  bool shouldRepaint(_CompactPatternPainter oldDelegate) => false;
}