import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  bool get _isAdminTab => _tabController.index == 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _error = null;
            _isSignUp = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          fullName: _nameCtrl.text,
        );
      } else {
        await AuthService.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }

      if (_isAdminTab && !AuthService.isAdminUser(AuthService.currentUser)) {
        await AuthService.signOut();
        throw Exception(
          'This account is not an admin account. Use user login instead.',
        );
      }
    } on PostgrestException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isAdminTab ? 'Admin Access' : 'Welcome to Child Connect';
    final subtitle = _isAdminTab
        ? 'Sign in with your admin credentials to review platform submissions.'
        : 'Sign in or create your account to continue your adoption journey.';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kider Style Portal',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFFF3F4F8),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textMedium,
                      tabs: const [
                        Tab(text: 'User Login'),
                        Tab(text: 'Admin Login'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isSignUp && !_isAdminTab) ...[
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (!_isSignUp || _isAdminTab) {
                                return null;
                              }
                              return Validators.name(
                                value,
                                fieldName: 'Full name',
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            return Validators.email(value);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            return Validators.password(
                              value,
                              strict: _isSignUp,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isSignUp ? 'Create Account' : 'Sign In',
                                  ),
                          ),
                        ),
                        if (!_isAdminTab)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () {
                                    setState(() {
                                      _isSignUp = !_isSignUp;
                                      _error = null;
                                    });
                                  },
                            child: Text(
                              _isSignUp
                                  ? 'Already have an account? Sign in'
                                  : 'New user? Create account',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isAdminTab)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Admin access is controlled by your role in the app_users table.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
