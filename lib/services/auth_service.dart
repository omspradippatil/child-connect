import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.sessionToken,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String sessionToken;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AppUser.fromMap(Map<String, dynamic> map, String sessionToken) {
    return AppUser(
      id: (map['id'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
      sessionToken: sessionToken,
    );
  }
}

class AuthService {
  AuthService._();

  static final SupabaseClient _client = Supabase.instance.client;
  static final ValueNotifier<AppUser?> _session = ValueNotifier<AppUser?>(null);

  static const String _kSessionToken = 'app_session_token';

  static ValueListenable<AppUser?> get authChanges => _session;

  static AppUser? get currentUser => _session.value;

  static bool get isSignedIn => currentUser != null;

  static bool isAdminUser([AppUser? user]) {
    return (user ?? currentUser)?.isAdmin ?? false;
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionToken = prefs.getString(_kSessionToken);

    if (sessionToken == null || sessionToken.isEmpty) {
      _session.value = null;
      return;
    }

    try {
      final response = await _client.rpc(
        'app_get_session_user',
        params: {'p_session_token': sessionToken},
      );

      final user = _parseUser(response, sessionToken);
      if (user == null) {
        await _setSession(null);
        return;
      }

      _session.value = user;
    } catch (_) {
      await _setSession(null);
    }
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

    final payload = _parseAuthPayload(response);
    final user = payload?.user;
    if (user == null) {
      throw Exception('Sign up failed. Please try again.');
    }
    await _setSession(user);
  }

  static Future<AppUser> signIn({
    required String email,
    required String password,
    bool persistSession = true,
  }) async {
    final response = await _client.rpc(
      'app_sign_in',
      params: {'p_email': email.trim(), 'p_password': password},
    );

    final payload = _parseAuthPayload(response);
    final user = payload?.user;
    if (user == null) {
      throw Exception('Invalid credentials.');
    }
    if (persistSession) {
      await _setSession(user);
    }
    return user;
  }

  static Future<void> establishSession(AppUser user) async {
    await _setSession(user);
  }

  static Future<void> signOut() async {
    final token = _session.value?.sessionToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _client.rpc('app_sign_out', params: {'p_session_token': token});
      } catch (_) {
        // Best-effort revoke; local cleanup still proceeds.
      }
    }
    await _setSession(null);
  }

  static _AuthPayload? _parseAuthPayload(dynamic response) {
    final map = _toMap(response);
    if (map == null) {
      return null;
    }

    final sessionToken = (map['session_token'] ?? '').toString();
    if (sessionToken.isEmpty) {
      return null;
    }

    final userMap = _toMap(map['user']);
    if (userMap == null) {
      return null;
    }

    final user = AppUser.fromMap(userMap, sessionToken);
    return _AuthPayload(user: user);
  }

  static AppUser? _parseUser(dynamic response, String sessionToken) {
    final map = _toMap(response);
    if (map == null) {
      return null;
    }
    return AppUser.fromMap(map, sessionToken);
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static Future<void> _setSession(AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_kSessionToken);
      _session.value = null;
      return;
    }

    await prefs.setString(_kSessionToken, user.sessionToken);
    _session.value = user;
  }
}

class _AuthPayload {
  const _AuthPayload({required this.user});

  final AppUser user;
}
