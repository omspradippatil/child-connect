import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/digilocker_service.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
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
        final signedInUser = await AuthService.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          persistSession: false,
        );

        if (signedInUser.role.toLowerCase() == 'user') {
          if (!mounted) {
            return;
          }
          final verified = await DigiLockerService.verifyUserIdentity(
            context,
            aadhaarNumber: _aadhaarCtrl.text,
            panNumber: _panCtrl.text,
          );
          if (!verified) {
            setState(() {
              _error =
                  'Verification requires Police Clearance Certificate, Aadhaar Card, and PAN Card.';
            });
            return;
          }
        }

        await AuthService.establishSession(signedInUser);
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
                    'Child Connect',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Create Your Account' : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'Sign up to continue your adoption journey.'
                        : 'Sign in to continue. Aadhaar and PAN are mandatory for user verification.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                Validators.name(value, fieldName: 'Full name'),
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
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) =>
                              Validators.password(value, strict: _isSignUp),
                        ),
                        if (!_isSignUp) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFDDE3F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DigiLocker KYC (Mandatory)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _aadhaarCtrl,
                                  keyboardType: TextInputType.number,
                                  maxLength: 12,
                                  decoration: const InputDecoration(
                                    labelText: 'Aadhaar Number',
                                    hintText: 'Enter 12-digit Aadhaar number',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (_isSignUp) {
                                      return null;
                                    }
                                    if (!DigiLockerService.isValidAadhaar(
                                      value ?? '',
                                    )) {
                                      return 'Enter a valid 12-digit Aadhaar number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _panCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  maxLength: 10,
                                  decoration: const InputDecoration(
                                    labelText: 'PAN Number',
                                    hintText: 'Enter PAN number',
                                    prefixIcon: Icon(
                                      Icons.credit_card_outlined,
                                    ),
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (_isSignUp) {
                                      return null;
                                    }
                                    if (!DigiLockerService.isValidPan(
                                      value ?? '',
                                    )) {
                                      return 'Enter a valid PAN number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _error = null;
                                    if (_isSignUp) {
                                      _aadhaarCtrl.clear();
                                      _panCtrl.clear();
                                    }
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
