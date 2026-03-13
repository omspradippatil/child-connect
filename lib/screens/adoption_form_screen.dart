import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_theme.dart';
import '../utils/app_data.dart';
import '../utils/validators.dart';

class AdoptionFormScreen extends StatefulWidget {
  final ChildProfile child;

  const AdoptionFormScreen({super.key, required this.child});

  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _streetAddressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _employerCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _annualIncomeCtrl = TextEditingController();
  final _familyMembersCtrl = TextEditingController();
  final _childrenCountCtrl = TextEditingController();
  final _familyBackgroundCtrl = TextEditingController();
  final _healthInsuranceCtrl = TextEditingController();
  final _referenceNameCtrl = TextEditingController();
  final _referencePhoneCtrl = TextEditingController();
  final _referenceEmailCtrl = TextEditingController();
  final _previousAdoptionExperienceCtrl = TextEditingController();
  final _motivationCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  String? _maritalStatus;
  String? _preferredAgeRange;
  String? _preferredGender;
  String? _residenceType;
  String? _ownershipStatus;
  String? _overallHealthStatus;
  bool _consentBackgroundCheck = false;
  bool _agreeHomeVisits = false;

  static const List<String> _statusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  static const List<String> _ageRangeOptions = [
    '0-2 years',
    '3-5 years',
    '6-10 years',
    '11-15 years',
    '16+ years',
  ];

  static const List<String> _genderOptions = [
    'Any',
    'Male',
    'Female',
    'Non-binary',
  ];

  static const List<String> _residenceTypeOptions = [
    'Apartment',
    'Independent House',
    'Townhouse',
    'Other',
  ];

  static const List<String> _ownershipStatusOptions = [
    'Owned',
    'Rented',
    'Family Property',
    'Other',
  ];

  static const List<String> _healthStatusOptions = [
    'Excellent',
    'Good',
    'Average',
    'Needs Attention',
  ];

  bool _submitted = false;
  bool _loading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _streetAddressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _employerCtrl.dispose();
    _occupationCtrl.dispose();
    _annualIncomeCtrl.dispose();
    _familyMembersCtrl.dispose();
    _childrenCountCtrl.dispose();
    _familyBackgroundCtrl.dispose();
    _healthInsuranceCtrl.dispose();
    _referenceNameCtrl.dispose();
    _referencePhoneCtrl.dispose();
    _referenceEmailCtrl.dispose();
    _previousAdoptionExperienceCtrl.dispose();
    _motivationCtrl.dispose();
    super.dispose();
  }

  String? _requiredDropdown(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _dateOfBirth = picked;
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      final yyyy = picked.year.toString();
      _dobCtrl.text = '$dd-$mm-$yyyy';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final fullName = '$firstName $lastName'.trim();
      final childrenCount = int.tryParse(_childrenCountCtrl.text.trim()) ?? 0;

      await Supabase.instance.client.from('adoption_applications').insert({
        'full_name': fullName,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T').first,
        'marital_status': _maritalStatus,
        'address_street': _streetAddressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'zip_code': _zipCodeCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'employer': _employerCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(),
        'annual_income': _annualIncomeCtrl.text.trim(),
        'preferred_age_range': _preferredAgeRange,
        'preferred_gender': _preferredGender,
        'number_of_family_members':
            int.tryParse(_familyMembersCtrl.text.trim()) ?? 0,
        'number_of_children': childrenCount,
        'has_children': childrenCount > 0,
        'family_background': _familyBackgroundCtrl.text.trim(),
        'residence_type': _residenceType,
        'ownership_status': _ownershipStatus,
        'health_insurance_provider': _healthInsuranceCtrl.text.trim(),
        'overall_health_status': _overallHealthStatus,
        'reference1_name': _referenceNameCtrl.text.trim(),
        'reference1_phone': _referencePhoneCtrl.text.trim(),
        'reference1_email': _referenceEmailCtrl.text.trim(),
        'consent_background_check': _consentBackgroundCheck,
        'agree_home_visits': _agreeHomeVisits,
        'previous_adoption_experience': _previousAdoptionExperienceCtrl.text
            .trim(),
        'motivation_for_adoption': _motivationCtrl.text.trim(),
        'reason': _motivationCtrl.text.trim(),
      });

      if (mounted) {
        setState(() => _submitted = true);
      }
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit: ${error.message}')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        title: const Text('Adoption Application Form'),
        leading: const BackButton(),
      ),
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
          'Request Submitted!',
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
            'Thank you for your interest. Our team will review your application and contact you within 48 hours.',
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
          child: const Text('Back to Children'),
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
          // Child info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.child.avatarColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.child.icon,
                    size: 34,
                    color: AppTheme.textDark.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.child.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '${widget.child.age} years • ${widget.child.location}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
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
            controller: _firstNameCtrl,
            decoration: const InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) => Validators.name(v, fieldName: 'First Name'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _lastNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) => Validators.name(v, fieldName: 'Last Name'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _dobCtrl,
            readOnly: true,
            onTap: _pickDateOfBirth,
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              hintText: 'dd-mm-yyyy',
              prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
            ),
            validator: (v) =>
                Validators.requiredText(v, fieldName: 'Date of Birth'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _maritalStatus,
            items: _statusOptions
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _maritalStatus = value),
            decoration: const InputDecoration(
              labelText: 'Marital Status',
              hintText: 'Select Status',
            ),
            validator: (v) => _requiredDropdown(v, 'Marital Status'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _streetAddressCtrl,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Street Address',
              prefixIcon: Icon(Icons.home_outlined, size: 20),
            ),
            validator: (v) => Validators.requiredText(v, fieldName: 'Address'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cityCtrl,
            decoration: const InputDecoration(labelText: 'City'),
            validator: (v) => Validators.requiredText(v, fieldName: 'City'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _stateCtrl,
            decoration: const InputDecoration(labelText: 'State'),
            validator: (v) => Validators.requiredText(v, fieldName: 'State'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _zipCodeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Zip Code'),
            validator: (v) => Validators.requiredText(v, fieldName: 'Zip Code'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            validator: Validators.phone,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: Validators.email,
          ),

          const SizedBox(height: 24),
          const Text(
            'Employment Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _employerCtrl,
            decoration: const InputDecoration(
              labelText: 'Employer',
              hintText: 'Current Employer',
            ),
            validator: (v) => Validators.requiredText(v, fieldName: 'Employer'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _occupationCtrl,
            decoration: const InputDecoration(labelText: 'Occupation'),
            validator: (v) =>
                Validators.requiredText(v, fieldName: 'Occupation'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _annualIncomeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Annual Income'),
            validator: (v) =>
                Validators.requiredText(v, fieldName: 'Annual Income'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Adoption Preferences',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _preferredAgeRange,
            items: _ageRangeOptions
                .map(
                  (range) => DropdownMenuItem<String>(
                    value: range,
                    child: Text(range),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _preferredAgeRange = value),
            decoration: const InputDecoration(
              labelText: 'Preferred Age Range',
              hintText: 'Select Age Range',
            ),
            validator: (v) => _requiredDropdown(v, 'Preferred Age Range'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _preferredGender,
            items: _genderOptions
                .map(
                  (gender) => DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _preferredGender = value),
            decoration: const InputDecoration(
              labelText: 'Preferred Gender',
              hintText: 'Select Gender',
            ),
            validator: (v) => _requiredDropdown(v, 'Preferred Gender'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Family Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _familyMembersCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Family Members',
            ),
            validator: (v) => Validators.requiredText(
              v,
              fieldName: 'Number of Family Members',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _childrenCountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Children',
              hintText: 'Number of Existing Children',
            ),
            validator: (v) =>
                Validators.requiredText(v, fieldName: 'Number of Children'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _familyBackgroundCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Family Background',
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                Validators.requiredText(v, fieldName: 'Family Background'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Housing Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _residenceType,
            items: _residenceTypeOptions
                .map(
                  (type) =>
                      DropdownMenuItem<String>(value: type, child: Text(type)),
                )
                .toList(),
            onChanged: (value) => setState(() => _residenceType = value),
            decoration: const InputDecoration(
              labelText: 'Type of Residence',
              hintText: 'Select Type',
            ),
            validator: (v) => _requiredDropdown(v, 'Type of Residence'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _ownershipStatus,
            items: _ownershipStatusOptions
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _ownershipStatus = value),
            decoration: const InputDecoration(
              labelText: 'Ownership Status',
              hintText: 'Select Status',
            ),
            validator: (v) => _requiredDropdown(v, 'Ownership Status'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Health Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _healthInsuranceCtrl,
            decoration: const InputDecoration(
              labelText: 'Health Insurance',
              hintText: 'Health Insurance Provider',
            ),
            validator: (v) =>
                Validators.requiredText(v, fieldName: 'Health Insurance'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _overallHealthStatus,
            items: _healthStatusOptions
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _overallHealthStatus = value),
            decoration: const InputDecoration(
              labelText: 'Overall Health Status',
              hintText: 'Select Status',
            ),
            validator: (v) => _requiredDropdown(v, 'Overall Health Status'),
          ),

          const SizedBox(height: 24),
          const Text(
            'References',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _referenceNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Reference 1 Name',
              hintText: 'Reference 1 - Full Name',
            ),
            validator: (v) =>
                Validators.requiredText(v, fieldName: 'Reference 1 Name'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _referencePhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Reference 1 Phone',
              hintText: 'Reference 1 - Phone',
            ),
            validator: Validators.phone,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _referenceEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Reference 1 Email',
              hintText: 'Reference 1 - Email',
            ),
            validator: Validators.email,
          ),

          const SizedBox(height: 24),
          const Text(
            'Background Check Consent',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consentBackgroundCheck,
            onChanged: (value) {
              setState(() => _consentBackgroundCheck = value ?? false);
            },
            title: const Text(
              'I consent to a background check as part of the adoption process',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _agreeHomeVisits,
            onChanged: (value) {
              setState(() => _agreeHomeVisits = value ?? false);
            },
            title: const Text(
              'I agree to home visits during the adoption process',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (!_consentBackgroundCheck || !_agreeHomeVisits)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Both consents are required to continue.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          const SizedBox(height: 24),
          const Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _previousAdoptionExperienceCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Previous Adoption Experience',
              hintText: 'Previous Adoption Experience (if any)',
              alignLabelWithHint: true,
            ),
            validator: (v) => Validators.requiredText(
              v,
              fieldName: 'Previous Adoption Experience',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _motivationCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Motivation for Adoption',
              hintText: 'Why do you want to adopt?',
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                Validators.minLength(v, 20, 'Motivation for Adoption'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _loading || !_consentBackgroundCheck || !_agreeHomeVisits
                  ? null
                  : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Adoption Application'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'By submitting, you agree to our terms of adoption.',
              style: TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
