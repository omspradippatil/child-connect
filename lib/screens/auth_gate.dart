import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AuthService.authChanges,
      builder: (context, user, _) {
        if (user == null) {
          return const LoginScreen();
        }

        if (user.isAdmin) {
          return const AdminDashboardScreen();
        }

        return const MainShell();
      },
    );
  }
}
