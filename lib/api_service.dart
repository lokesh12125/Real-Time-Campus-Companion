import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'timetable_model.dart'; 

final _storage = const FlutterSecureStorage();
const _tokenKey = 'auth_token';
const _userKey = 'user_profile';
const _userBranchKey = 'user_branch';
const _userSectionKey = 'user_section';
const _userSemesterKey = 'user_semester';
const _userRoleKey = 'user_role';

class ApiService {
  // Update IP if needed: 10.0.2.2 for Emulator, 127.0.0.1 for iOS/Web
  static const String baseUrl = 'http://127.0.0.1:4000';

  // ===========================================================================
  // SECTION 1: HEADERS & TOKENS
  // ===========================================================================

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await readToken();
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  static Future<void> saveToken(String token) async => await _storage.write(key: _tokenKey, value: token);
  static Future<String?> readToken() async => await _storage.read(key: _tokenKey);
  static Future<void> deleteToken() async => await _storage.delete(key: _tokenKey);

  static Future<void> saveUserProfile(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
    if (user['branch'] != null) await _storage.write(key: _userBranchKey, value: user['branch'].toString());
    if (user['section'] != null) await _storage.write(key: _userSectionKey, value: user['section'].toString());
    if (user['semester'] != null) await _storage.write(key: _userSemesterKey, value: user['semester'].toString());
    if (user['role'] != null) await _storage.write(key: _userRoleKey, value: user['role'].toString());
  }

  static Future<Map<String, dynamic>?> readUserProfile() async {
    final s = await _storage.read(key: _userKey);
    return s == null ? null : jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> deleteUserProfile() async {
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _userBranchKey);
    await _storage.delete(key: _userSectionKey);
    await _storage.delete(key: _userSemesterKey);
    await _storage.delete(key: _userRoleKey);
  }

  static Future<String?> readBranch() async => await _storage.read(key: _userBranchKey);
  static Future<String?> readSection() async => await _storage.read(key: _userSectionKey);
  static Future<String?> readSemester() async => await _storage.read(key: _userSemesterKey);
  static Future<String?> readRole() async => await _storage.read(key: _userRoleKey);

  // ===========================================================================
  // SECTION 6: USER MANAGEMENT
  // ===========================================================================

  static Future<Map<String, dynamic>> getUserById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/$id'), 
      headers: await _headers(auth: true)
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['user'];
    } else {
      throw Exception('Failed to fetch user details');
    }
  }

  static Future<Map<String, dynamic>> createUserWithProfile({
    required String name,
    required String email,
    required String password,
    required DateTime dob,
    required String profilePath,
    required String role,
    required String rollNo,
    required String semester,
    required String section,
    required String branch,
    String? cabinRoom,
    bool? availability,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _headers(auth: true));

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['dob'] = dob.toIso8601String();
    request.fields['role'] = role;
    request.fields['rollNo'] = rollNo;
    request.fields['semester'] = semester;
    request.fields['section'] = section;
    request.fields['branch'] = branch;
    
    if (cabinRoom != null) request.fields['cabinRoom'] = cabinRoom;
    if (availability != null) request.fields['availability'] = availability.toString();

    if (profilePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile', profilePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorJson = jsonDecode(response.body);
      throw Exception(errorJson['message'] ?? 'Server Error');
    }
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final response = await http.get(Uri.parse('$baseUrl/api/user/search?query=$query'), headers: await _headers(auth: true));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to search users');
  }

  // UPDATED: To return TeacherSearchResult with cabin info
  static Future<List<TeacherSearchResult>> searchTeachers(String query) async {
    if (query.isEmpty) return [];
    final response = await http.get(Uri.parse('$baseUrl/api/user/teachers?search=$query'), headers: await _headers(auth: true));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => TeacherSearchResult.fromJson(item)).toList();
    }
    throw Exception('Failed to search teachers');
  }

  static Future<void> updateUserById({
    required String id,
    String? name,
    String? email,
    String? password,
    DateTime? dob,
    String? role,
    String? rollNo,
    String? semester,
    String? section,
    String? branch,
    String? profilePath,
    String? cabinRoom, 
    bool? availability,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user/$id');
    var request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(await _headers(auth: true));

    if (name != null) request.fields['name'] = name;
    if (email != null) request.fields['email'] = email;
    if (password != null && password.isNotEmpty) request.fields['password'] = password;
    if (dob != null) request.fields['dob'] = dob.toIso8601String();
    if (role != null) request.fields['role'] = role;
    if (rollNo != null) request.fields['rollNo'] = rollNo;
    if (semester != null) request.fields['semester'] = semester;
    if (section != null) request.fields['section'] = section;
    if (branch != null) request.fields['branch'] = branch;
    if (cabinRoom != null) request.fields['cabinRoom'] = cabinRoom;
    if (availability != null) request.fields['availability'] = availability.toString();

    if (profilePath != null && profilePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile', profilePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Update failed');
    }
  }

  static Future<void> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/user/$id'), headers: await _headers(auth: true));
    if (response.statusCode != 200) throw Exception('Delete failed: ${response.body}');
  }

  // ===========================================================================
  // SECTION 2: COURSES
  // ===========================================================================
  static Future<void> addCourse(Map<String, dynamic> courseData) async {
    final response = await http.post(Uri.parse('$baseUrl/api/courses'), headers: await _headers(auth: true), body: jsonEncode(courseData));
    if (response.statusCode != 201) throw Exception('Failed to add course: ${response.body}');
  }

  static Future<List<Course>> getCourses(String branch, String semester, String section) async {
    final response = await http.get(Uri.parse('$baseUrl/api/courses?branch=$branch&semester=$semester&section=$section'), headers: await _headers(auth: true));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((course) => Course.fromJson(course)).toList();
    }
    throw Exception('Failed to load courses');
  }

  static Future<void> deleteCourse(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/courses/$id'), headers: await _headers(auth: true));
    if (response.statusCode != 200) throw Exception('Failed to delete course: ${response.body}');
  }

  // ===========================================================================
  // SECTION 3: TIMETABLE
  // ===========================================================================
  static Future<void> addTimetable(Map<String, dynamic> timetableData) async {
    final response = await http.post(Uri.parse('$baseUrl/api/timetable'), headers: await _headers(auth: true), body: jsonEncode(timetableData));
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body)['message'] ?? 'Unknown error';
      throw Exception(error);
    }
  }

  static Future<void> updateTimetable(Map<String, dynamic> timetableData) async {
    final response = await http.put(Uri.parse('$baseUrl/api/timetable'), headers: await _headers(auth: true), body: jsonEncode(timetableData));
    if (response.statusCode != 200) throw Exception('Failed to update timetable: ${response.body}');
  }

  static Future<Timetable> getTimetable(String branch, String semester, String section) async {
    final response = await http.get(Uri.parse('$baseUrl/api/timetable?branch=$branch&semester=$semester&section=$section'), headers: await _headers(auth: true));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Timetable.fromJson(data['timetable']);
    } else if (response.statusCode == 404) {
      throw Exception("Not Found");
    }
    throw Exception('Failed to load timetable');
  }

  static Future<Timetable> getMyTimetable() async {
    final response = await http.get(Uri.parse('$baseUrl/api/timetable/me'), headers: await _headers(auth: true));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Timetable.fromJson(data['timetable']);
    }
    throw Exception('No timetable found for your class.');
  }

  static Future<List<TimetableDay>> getTeacherTimetable() async {
    final response = await http.get(Uri.parse('$baseUrl/api/timetable/teacher'), headers: await _headers(auth: true));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var list = data['grid'] as List;
      return list.map((i) => TimetableDay.fromJson(i)).toList();
    }
    throw Exception('Failed to load teacher schedule');
  }

  static Future<void> updateSlot({
    required String semester, required String branch, required String section,
    required String dayName, required int slotIndex, bool? isCancelled, String? newRoom,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/timetable/slot'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'semester': semester, 'branch': branch, 'section': section,
        'dayName': dayName, 'slotIndex': slotIndex,
        if (isCancelled != null) 'isCancelled': isCancelled,
        if (newRoom != null) 'newRoom': newRoom,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update slot');
  }

  // ===========================================================================
  // SECTION 7: EVENTS
  // ===========================================================================
  static Future<List<dynamic>> getAllEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/api/events'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['events'];
    }
    throw Exception('Failed to load events');
  }

  static Future<void> createEvent({
    required String title, required String description, required DateTime date,
    required String imageUrl, required List<String> regulations, required String registrationLink,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/events'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'title': title, 'description': description, 'date': date.toIso8601String(),
        'imageUrl': imageUrl, 'regulations': regulations, 'registrationLink': registrationLink,
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to create event: ${response.body}');
  }

  static Future<void> updateEvent({
    required String eventId, required String title, required String description,
    required DateTime date, required String imageUrl, required List<String> regulations, required String registrationLink,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/events/$eventId'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'title': title, 'description': description, 'date': date.toIso8601String(),
        'imageUrl': imageUrl, 'regulations': regulations, 'registrationLink': registrationLink,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update event: ${response.body}');
  }

  static Future<void> deleteEvent(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/events/$id'), headers: await _headers(auth: true));
    if (response.statusCode != 200) throw Exception('Failed to delete event');
  }

  // ===========================================================================
  // SECTION 8: CLASSROOMS
  // ===========================================================================
  static Future<List<dynamic>> getClassroomStatus() async {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayName = days[now.weekday - 1];
    int slotIndex = _calculateCurrentSlotIndex();

    final response = await http.get(Uri.parse('$baseUrl/api/classrooms/status?day=$dayName&slotIndex=$slotIndex'), headers: await _headers(auth: true));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Failed to load classroom status');
  }

  static int _calculateCurrentSlotIndex() {
    final hour = DateTime.now().hour;
    if (hour < 9) return 0;
    if (hour > 17) return 8;
    return hour - 9;
  }

  // ===========================================================================
  // SECTION 5: AUTH
  // ===========================================================================
  static Future<Map> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final res = await http.post(url, headers: await _headers(), body: jsonEncode({'email': email, 'password': password}));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : {};
    if (res.statusCode == 200) {
      if (body['token'] != null) await saveToken(body['token']);
      if (body['user'] != null) await saveUserProfile(body['user'] as Map<String, dynamic>);
      return body;
    }
    throw Exception(body['error'] ?? 'Login failed (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> forgotPassword({required String email, required String dob}) async {
    final url = Uri.parse('$baseUrl/api/auth/forgot-password');
    final body = jsonEncode({'email': email, 'dob': dob});
    final res = await http.post(url, headers: await _headers(), body: body);
    if (res.statusCode == 200 || res.statusCode == 201) return jsonDecode(res.body);
    final decoded = jsonDecode(res.body);
    throw Exception(decoded['error'] ?? 'Forgot password failed');
  }
}