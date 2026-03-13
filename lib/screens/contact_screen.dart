import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _msgCtrl.dispose();
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
      appBar: AppBar(title: const Text('Contact Us')),
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
          'Message Sent!',
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
            'Thank you for reaching out. We\'ll get back to you within 1–2 business days.',
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
          onPressed: () {
            setState(() {
              _submitted = false;
              _nameCtrl.clear();
              _emailCtrl.clear();
              _msgCtrl.clear();
            });
          },
          child: const Text('Send Another Message'),
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
          // Info cards
          Row(
            children: [
              Expanded(child: _infoTile(Icons.phone, '+91 98765 43210')),
              const SizedBox(width: 10),
              Expanded(
                child: _infoTile(Icons.email_outlined, 'hello@childconnect.in'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoTile(
            Icons.location_on_outlined,
            '12 NGO Lane, Bandra, Mumbai – 400050',
          ),
          const SizedBox(height: 24),
          const Text(
            'Send a Message',
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
              labelText: 'Your Name',
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
            controller: _msgCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Your Message',
              hintText: 'How can we help you?',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Message cannot be empty'
                : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Send Message'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
