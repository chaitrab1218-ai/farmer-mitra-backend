import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService — Email & Password Authentication + Neon DB Integration
// ─────────────────────────────────────────────────────────────────────────────

// Works on Web, Windows Desktop, and USB-connected Android phones via adb reverse.
const String kApiBase = 'http://localhost:5000';

const _kTokenKey = 'km_access_token';
const _kUserKey  = 'km_user_profile';

class UserProfile {
  final String id;
  final String phone;
  final String email;
  final String displayName;

  const UserProfile({
    required this.id,
    required this.phone,
    required this.email,
    required this.displayName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id:          (j['id']?.toString() ?? j['sub'] ?? '') as String,
        phone:       (j['phone'] ?? '') as String,
        email:       (j['email'] ?? '') as String,
        displayName: (j['displayName'] ?? j['name'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'id':          id,
        'phone':       phone,
        'email':       email,
        'displayName': displayName,
      };
}

class NeonAuthService {
  static const _timeout = Duration(seconds: 15);

  static String?      _accessToken;
  static UserProfile? _currentUser;

  static final List<VoidCallback> _listeners = [];
  static void addListener(VoidCallback listener) => _listeners.add(listener);
  static void removeListener(VoidCallback listener) => _listeners.remove(listener);
  static void _notifyListeners() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  static String?      get accessToken => _accessToken;
  static UserProfile? get currentUser => _currentUser;
  static bool         get isLoggedIn  => _accessToken != null;

  // ── Restore on cold start ─────────────────────────────────────────────────
  static Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_kTokenKey);
    final userJson = prefs.getString(_kUserKey);
    if (userJson != null) {
      try {
        _currentUser = UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    _notifyListeners();
  }

  static Future<void> _persist(String token, UserProfile user) async {
    _accessToken = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
    _notifyListeners();
  }

  static Future<void> signOut() async {
    _accessToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserKey);
    _notifyListeners();
  }

  // ── Headers ───────────────────────────────────────────────────────────────
  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        'Origin': 'http://localhost:5000',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ── Email Login ───────────────────────────────────────────────────────────
  /// Returns null on success, or an error message string.
  static Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kApiBase/api/auth/login'),
            headers: authHeaders,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final token = body['token'] as String;
        final user = UserProfile.fromJson(body['user'] as Map<String, dynamic>);
        await _persist(token, user);
        return null; // success
      }
      return body['message'] as String? ?? 'Invalid email or password.';
    } on Exception catch (e) {
      return 'Network error: $e';
    }
  }

  // ── Email Sign Up ─────────────────────────────────────────────────────────
  /// Returns null on success, or an error message string.
  static Future<String?> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? phone,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kApiBase/api/auth/register'),
            headers: authHeaders,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
              'displayName': displayName?.trim() ?? '',
              'phone': phone?.trim() ?? '',
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
        final token = body['token'] as String;
        final user = UserProfile.fromJson(body['user'] as Map<String, dynamic>);
        await _persist(token, user);
        return null; // success
      }
      return body['message'] as String? ?? 'Registration failed.';
    } on Exception catch (e) {
      return 'Network error: $e';
    }
  }
}
