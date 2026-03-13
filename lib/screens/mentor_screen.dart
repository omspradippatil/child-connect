import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _selectedArea;
  bool _submitted = false;

  final List<String> _areas = [
    'Art & Creativity',
    'Sports & Fitness',
    'Literacy & Reading',
    'Music',
    'Science & Technology',
    'Life Skills',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _skillsCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(title: const Text('Become a Mentor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.successGreen,
            size: 54,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Application Received!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Thank you for volunteering as a mentor! Our team will review your profile and get in touch with you soon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.handshake_rounded,
                  color: AppTheme.successGreen,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mentors spend just 2–4 hours per week guiding a child towards a brighter future.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
          ),
          const SizedBox(height: 24),
          const Text(
            'Mentoring Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedArea,
            decoration: InputDecoration(
              labelText: 'Area of Expertise',
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.divider,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryOrange,
                  width: 1.5,
                ),
              ),
            ),
            items: _areas
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) => setState(() => _selectedArea = v),
            validator: (v) => (v == null) ? 'Please select an area' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _skillsCtrl,
            decoration: const InputDecoration(
              labelText: 'Key Skills',
              hintText: 'e.g. Drawing, Guitar, Cricket...',
              prefixIcon: Icon(Icons.star_outline, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Skills are required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'About You',
              hintText:
                  'Tell us about yourself and your motivation to mentor...',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v == null || v.trim().length < 20)
                ? 'Please write at least 20 characters'
                : null,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
              ),
              child: const Text('Submit Mentor Application'),
            ),
          ),
        ],
      ),
    );
  }
}
