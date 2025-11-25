import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class AddUserPage extends StatefulWidget {
  final ApiService? api;
  const AddUserPage({super.key, this.api});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // --- State Variables ---
  String name = '';
  String email = '';
  String password = '';
  String rollNo = '';
  String branch = '';
  String semester = '';
  String section = '';
  String role = 'student'; // Default role
  DateTime? dob;
  File? _profileFile;

  // Teacher Specific State
  String cabinRoom = '';
  // Removed availability state (defaults to true in backend)

  bool _isSubmitting = false;

  // Dropdown Options
  final List<String> _semesterOptions = [
    'S1',
    'S2',
    'S3',
    'S4',
    'S5',
    'S6',
    'S7',
    'S8',
  ];
  String? _selectedSemester;

  // Role Options
  final List<String> _roleOptions = [
    'student',
    'classrep',
    'teacher',
    'admin',
    'staff',
  ];

  // --- Helper: Check Role Requirements ---
  bool get isStudent => role == 'student' || role == 'classrep';
  bool get isTeacher => role == 'teacher';
  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';

  // Field Visibility/Enable State
  bool get enableRollNo => isStudent || isAdmin;
  bool get enableBranch => isStudent || isTeacher || isAdmin;
  bool get enableSemester => isStudent || isAdmin;
  bool get enableSection => isStudent || isAdmin;

  // Field Validation Logic (Is it Mandatory?)
  bool get requiredRollNo => isStudent; // Student & ClassRep must have rollNo
  bool get requiredBranch =>
      isStudent || isTeacher; // Student, ClassRep, and Teacher
  bool get requiredSemester => isStudent;
  bool get requiredSection => isStudent;
  bool get requiredDob => true; // DOB required for all roles

  // --- Image Picking Logic ---
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (file != null) {
                    setState(() => _profileFile = File(file.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (file != null) {
                    setState(() => _profileFile = File(file.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => dob = picked);
  }

  // --- Submit Logic ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profileFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a profile image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // DOB Check - Required for all
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Date of Birth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      // Clear disabled fields before sending
      if (!enableRollNo) rollNo = '';
      if (!enableBranch) branch = '';
      if (!enableSemester) semester = '';
      if (!enableSection) section = '';

      // Clear teacher fields if not teacher
      if (!isTeacher) {
        cabinRoom = '';
      }

      final result = await ApiService.createUserWithProfile(
        name: name,
        email: email,
        password: password,
        dob: dob!,
        profilePath: _profileFile!.path,
        role: role,
        rollNo: rollNo,
        semester: semester,
        section: section,
        branch: branch,
        cabinRoom: isTeacher ? cabinRoom : null,
        // availability is NOT sent, so backend uses default (true)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Creation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledColor = isDark ? Colors.grey[800] : Colors.grey[200];

    return Scaffold(
      appBar: AppBar(title: const Text('Add New User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Circular Image Editor
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                      ),
                      child: ClipOval(
                        child: _profileFile != null
                            ? Image.file(
                                _profileFile!,
                                fit: BoxFit.cover,
                                width: 130,
                                height: 130,
                              )
                            : Icon(
                                Icons.person,
                                size: 70,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal,
                            border: Border.all(
                              color: isDark ? Colors.grey[900]! : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // ROLE SELECTOR
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  border: OutlineInputBorder(),
                ),
                value: role,
                items: _roleOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      role = newValue;
                      // Reset dependent fields
                      _selectedSemester = null;
                      semester = '';
                      section = '';
                      rollNo = '';
                      branch = '';
                      // Reset teacher fields
                      cabinRoom = '';
                    });
                  }
                },
              ),
              const SizedBox(height: 15),

              // 2. Personal Info - Name
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => name = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 15),

              // Email
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => email = v?.trim().toLowerCase() ?? '',
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 15),

              // Password
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSaved: (v) => password = v ?? '',
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 15),

              // 3. Roll No and Section Row
              Row(
                children: [
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: !enableRollNo,
                      child: Opacity(
                        opacity: enableRollNo ? 1.0 : 0.5,
                        child: TextFormField(
                          enabled: enableRollNo,
                          decoration: InputDecoration(
                            labelText: 'Roll No',
                            border: const OutlineInputBorder(),
                            filled: !enableRollNo,
                            fillColor: !enableRollNo ? disabledColor : null,
                          ),
                          onSaved: (v) => rollNo = v?.trim() ?? '',
                          validator: (v) {
                            if (requiredRollNo &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: !enableSection,
                      child: Opacity(
                        opacity: enableSection ? 1.0 : 0.5,
                        child: TextFormField(
                          enabled: enableSection,
                          decoration: InputDecoration(
                            labelText: 'Section',
                            border: const OutlineInputBorder(),
                            filled: !enableSection,
                            fillColor: !enableSection ? disabledColor : null,
                          ),
                          onSaved: (v) => section = v?.trim() ?? '',
                          validator: (v) {
                            if (requiredSection &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 4. Semester & Branch
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: !enableSemester,
                      child: Opacity(
                        opacity: enableSemester ? 1.0 : 0.5,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Semester',
                            border: const OutlineInputBorder(),
                            filled: !enableSemester,
                            fillColor: !enableSemester ? disabledColor : null,
                          ),
                          value: _selectedSemester,
                          items: _semesterOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: enableSemester
                              ? (newValue) {
                                  setState(() {
                                    _selectedSemester = newValue;
                                    semester = newValue ?? '';
                                  });
                                }
                              : null,
                          validator: (value) {
                            if (requiredSemester && value == null)
                              return 'Required';
                            return null;
                          },
                          onSaved: (value) => semester = value ?? '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: !enableBranch,
                      child: Opacity(
                        opacity: enableBranch ? 1.0 : 0.5,
                        child: TextFormField(
                          enabled: enableBranch,
                          decoration: InputDecoration(
                            labelText: 'Branch',
                            border: const OutlineInputBorder(),
                            hintText: 'e.g. CSE',
                            filled: !enableBranch,
                            fillColor: !enableBranch ? disabledColor : null,
                          ),
                          onSaved: (v) => branch = v?.trim() ?? '',
                          validator: (v) {
                            if (requiredBranch &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // --- TEACHER SPECIFIC FIELDS ---
              if (isTeacher) ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Cabin Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.room),
                  ),
                  onSaved: (v) => cabinRoom = v?.trim() ?? '',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required for teacher'
                      : null,
                ),
                // Availability Toggle REMOVED
                const SizedBox(height: 15),
              ],

              // 5. DOB Picker
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    dob == null
                        ? 'Select Date'
                        : DateFormat.yMMMd().format(dob!),
                    style: TextStyle(
                      color: dob == null
                          ? Colors.grey[600]
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 6. Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
