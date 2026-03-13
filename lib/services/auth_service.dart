import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: (map['id'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
    );
  }
}

class AuthService {
  AuthService._();

  static final SupabaseClient _client = Supabase.instance.client;
  static final ValueNotifier<AppUser?> _session = ValueNotifier<AppUser?>(null);

  static const String _kUserId = 'app_user_id';
  static const String _kUserName = 'app_user_name';
  static const String _kUserEmail = 'app_user_email';
  static const String _kUserRole = 'app_user_role';

  static ValueListenable<AppUser?> get authChanges => _session;

  static AppUser? get currentUser => _session.value;

  static bool get isSignedIn => currentUser != null;

  static bool isAdminUser([AppUser? user]) {
    return (user ?? currentUser)?.isAdmin ?? false;
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kUserId);
    final fullName = prefs.getString(_kUserName);
    final email = prefs.getString(_kUserEmail);
    final role = prefs.getString(_kUserRole);

    if (id == null || fullName == null || email == null || role == null) {
      _session.value = null;
      return;
    }

    _session.value = AppUser(
      id: id,
      fullName: fullName,
      email: email,
      role: role,
    );
  }

  static Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.rpc(
      'app_sign_up',
      params: {
        'p_full_name': (fullName ?? '').trim(),
        'p_email': email.trim(),
        'p_password': password,
      },
    );

    final user = _parseUser(response);
    if (user == null) {
      throw Exception('Sign up failed. Please try again.');
    }
    await _setSession(user);
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.rpc(
      'app_sign_in',
      params: {'p_email': email.trim(), 'p_password': password},
    );

    final user = _parseUser(response);
    if (user == null) {
      throw Exception('Invalid credentials.');
    }
    await _setSession(user);
  }

  static Future<void> signOut() async {
    await _setSession(null);
  }

  static AppUser? _parseUser(dynamic response) {
    if (response is Map<String, dynamic>) {
      return AppUser.fromMap(response);
    }

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return AppUser.fromMap(first);
      }
      if (first is Map) {
        return AppUser.fromMap(Map<String, dynamic>.from(first));
      }
    }

    if (response is Map) {
      return AppUser.fromMap(Map<String, dynamic>.from(response));
    }

    return null;
  }

  static Future<void> _setSession(AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_kUserId);
      await prefs.remove(_kUserName);
      await prefs.remove(_kUserEmail);
      await prefs.remove(_kUserRole);
      _session.value = null;
      return;
    }

    await prefs.setString(_kUserId, user.id);
    await prefs.setString(_kUserName, user.fullName);
    await prefs.setString(_kUserEmail, user.email);
    await prefs.setString(_kUserRole, user.role);
    _session.value = user;
  }
}
