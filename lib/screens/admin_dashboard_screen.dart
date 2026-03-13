import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;

  int _contactCount = 0;
  int _adoptionCount = 0;
  int _mentorCount = 0;

  List<Map<String, dynamic>> _latestContacts = const [];
  List<Map<String, dynamic>> _latestAdoptions = const [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null || !user.isAdmin) {
        throw Exception('This account does not have admin access.');
      }

      final response = await Supabase.instance.client.rpc(
        'app_admin_dashboard_snapshot',
        params: {'p_session_token': user.sessionToken},
      );

      final data = Map<String, dynamic>.from(response as Map);
      final latestContactsRaw = data['latest_contacts'] as List? ?? const [];
      final latestAdoptionsRaw = data['latest_adoptions'] as List? ?? const [];

      setState(() {
        _latestContacts = latestContactsRaw
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _latestAdoptions = latestAdoptionsRaw
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _contactCount = (data['contact_count'] as num?)?.toInt() ?? 0;
        _adoptionCount = (data['adoption_count'] as num?)?.toInt() ?? 0;
        _mentorCount = (data['mentor_count'] as num?)?.toInt() ?? 0;
      });
    } on PostgrestException catch (error) {
      setState(() {
        _error = 'Dashboard query failed: ${error.message}';
      });
    } catch (error) {
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _loadDashboard)
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricCard(
                        label: 'Contact Messages',
                        value: _contactCount,
                        icon: Icons.mail_outline,
                        color: AppTheme.accentBlue,
                      ),
                      _MetricCard(
                        label: 'Adoption Requests',
                        value: _adoptionCount,
                        icon: Icons.favorite_border,
                        color: AppTheme.primaryOrange,
                      ),
                      _MetricCard(
                        label: 'Mentor Requests',
                        value: _mentorCount,
                        icon: Icons.handshake_outlined,
                        color: AppTheme.successGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SubmissionSection(
                    title: 'Latest Contact Messages',
                    rows: _latestContacts,
                  ),
                  const SizedBox(height: 14),
                  _SubmissionSection(
                    title: 'Latest Adoption Requests',
                    rows: _latestAdoptions,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Color(0xFFC62828)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }
}

class _SubmissionSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> rows;

  const _SubmissionSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Text(
              'No records yet.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
            ),
          ...rows.map(
            (row) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                row['full_name']?.toString() ?? 'Unnamed',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(row['status']?.toString() ?? 'new'),
              trailing: Text(
                (row['created_at']?.toString() ?? '')
                    .replaceFirst('T', ' ')
                    .split('.')
                    .first,
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
