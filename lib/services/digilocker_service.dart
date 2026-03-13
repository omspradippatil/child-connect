import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class DigiLockerService {
  DigiLockerService._();

  static const String _digiLockerAuthEndpoint =
      'https://api.digitallocker.gov.in/public/oauth2/1/authorize';
  static const String _clientId =
      'DEMO_CLIENT_ID'; // Placeholder for educational purposes
  static const String _docAadhaar = 'Aadhaar Card';
  static const String _docPan = 'PAN Card';
  static const String _docPolice = 'Police Clearance Certificate';
  static final ImagePicker _imagePicker = ImagePicker();

  /// This initiates the OAuth flow by opening the DigiLocker authorization page.
  static Future<void> launchDigiLockerLogin() async {
    final url = Uri.parse(
      '$_digiLockerAuthEndpoint?response_type=code&client_id=$_clientId&redirect_uri=childconnect://oauth&state=12345',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch DigiLocker authentication page.');
    }
  }

  /// Exchanges the authorization code for an access token.
  /// Simulated here since we are avoiding complex native deep linking for the project.
  static Future<String> exchangeAuthCodeForToken(String code) async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network request
    if (code.isEmpty) throw Exception('Invalid authorization code');
    return 'demo_access_token_${Random().nextInt(10000)}';
  }

  /// Fetches the user documents using the access token.
  /// Simulated API call.
  static Future<List<String>> fetchUserDocuments(String token) async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network request
    // Simulate finding required documents for educational flow.
    return [_docAadhaar, _docPan, _docPolice];
  }

  /// Complete flow: Shows a verification dialog, validates inputs, then verifies.
  static Future<bool> verifyUserIdentity(BuildContext context) async {
    try {
      if (!context.mounted) return false;

      final result = await _showVerificationForm(context);

      if (result == null || !result.confirmed || result.code.isEmpty) {
        return false;
      }

      if (!isValidAadhaar(result.aadhaarNumber) ||
          !isValidPan(result.panNumber)) {
        return false;
      }

      final token = await exchangeAuthCodeForToken(result.code);
      final docs = await fetchUserDocuments(token);

      final hasRequiredDocs =
          docs.contains(_docAadhaar) &&
          docs.contains(_docPan) &&
          docs.contains(_docPolice) &&
          result.policeCertificate != null;

      return hasRequiredDocs;
    } catch (e) {
      debugPrint('DigiLocker verification failed: $e');
      return false;
    }
  }

  static Future<_VerificationResult?> _showVerificationForm(
    BuildContext context,
  ) {
    final formKey = GlobalKey<FormState>();
    final aadhaarController = TextEditingController();
    final panController = TextEditingController();
    XFile? selectedCertificate;
    bool busy = false;

    return showDialog<_VerificationResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> selectCertificate(ImageSource source) async {
              try {
                setModalState(() => busy = true);
                final file = await _imagePicker.pickImage(
                  source: source,
                  imageQuality: 85,
                );
                if (file == null) return;
                setModalState(() => selectedCertificate = file);
              } finally {
                setModalState(() => busy = false);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.verified_user_outlined,
                                color: Color(0xFFE65100),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'DigiLocker KYC Verification',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Complete identity verification by providing your Aadhaar, PAN, and uploading a Police Clearance Certificate.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: aadhaarController,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          decoration: const InputDecoration(
                            labelText: 'Aadhaar Number',
                            hintText: 'Enter 12-digit Aadhaar number',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Aadhaar number is required';
                            }
                            final clean =
                                value.replaceAll(RegExp(r'\s+'), '');
                            if (!isValidAadhaar(clean)) {
                              return 'Enter a valid 12-digit Aadhaar number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: panController,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: 'PAN Number',
                            hintText: 'Enter PAN (e.g. ABCPE1234F)',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'PAN number is required';
                            }
                            if (!isValidPan(value.trim().toUpperCase())) {
                              return 'Enter a valid PAN number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFDDE3F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Police Clearance Certificate',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedCertificate == null
                                    ? 'No file selected yet.'
                                    : 'Selected: ${selectedCertificate!.name}',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: busy
                                          ? null
                                          : () => selectCertificate(
                                                ImageSource.gallery,
                                              ),
                                      icon: const Icon(
                                        Icons.photo_library_outlined,
                                      ),
                                      label: const Text('Gallery'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: busy
                                          ? null
                                          : () => selectCertificate(
                                                ImageSource.camera,
                                              ),
                                      icon: const Icon(
                                        Icons.photo_camera_outlined,
                                      ),
                                      label: const Text('Camera'),
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedCertificate != null) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: FutureBuilder<Uint8List>(
                                    future:
                                        selectedCertificate!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 160,
                                          child: Center(
                                            child:
                                                CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return const SizedBox(
                                          height: 160,
                                          child: Center(
                                            child: Text(
                                                'Error loading image'),
                                          ),
                                        );
                                      }
                                      return Image.memory(
                                        snapshot.data!,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: busy
                                    ? null
                                    : () => Navigator.pop(ctx, null),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: busy
                                    ? null
                                    : () {
                                        final isValid = formKey
                                                .currentState
                                                ?.validate() ??
                                            false;
                                        if (!isValid) return;
                                        if (selectedCertificate == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Upload the Police Clearance Certificate.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.pop(
                                          ctx,
                                          _VerificationResult(
                                            confirmed: true,
                                            code:
                                                'sample_auth_code_${Random().nextInt(99999)}',
                                            aadhaarNumber: aadhaarController
                                                .text
                                                .replaceAll(
                                                    RegExp(r'\s+'), ''),
                                            panNumber: panController.text
                                                .trim()
                                                .toUpperCase(),
                                            policeCertificate:
                                                selectedCertificate,
                                          ),
                                        );
                                      },
                                child: busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Verify & Continue'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Validates Aadhaar number using the Verhoeff checksum algorithm.
  /// This is the same algorithm UIDAI uses to generate valid Aadhaar numbers.
  /// A random 12-digit number like "123456789876" will fail this check.
  static bool _isValidAadhaar(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '');

    // Must be exactly 12 digits
    if (!RegExp(r'^\d{12}$').hasMatch(normalized)) return false;

    // Must not start with 0 or 1 (UIDAI rule)
    if (normalized.startsWith('0') || normalized.startsWith('1')) return false;

    // Must not be all same digits (e.g. 222222222222)
    if (RegExp(r'^(\d)\1{11}$').hasMatch(normalized)) return false;

    // Verhoeff checksum validation
    // Multiplication table
    const d = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
      [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
      [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
      [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
      [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
      [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
      [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
      [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
      [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
    ];

    // Permutation table
    const p = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
      [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
      [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
      [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
      [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
      [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
      [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
    ];

    int c = 0;
    final digits = normalized.split('').reversed.toList();
    for (int i = 0; i < digits.length; i++) {
      c = d[c][p[i % 8][int.parse(digits[i])]];
    }
    return c == 0;
  }

  /// Validates PAN number with strict format and logical checks.
  /// PAN format: ABCDE1234F
  /// - Chars 1-3: Alphabetic (AAA-ZZZ)
  /// - Char 4: Holder type (C, P, H, F, A, T, B, L, J, G — valid types only)
  /// - Char 5: First letter of surname (A-Z)
  /// - Chars 6-9: Sequential number (0001-9999)
  /// - Char 10: Alphabetic check digit
  static bool _isValidPan(String value) {
    final normalized = value.trim().toUpperCase();

    // Basic format: 5 letters, 4 digits, 1 letter
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(normalized)) return false;

    // 4th character must be a valid holder type
    const validHolderTypes = {
      'A', // Association of Persons
      'B', // Body of Individuals
      'C', // Company
      'F', // Firm
      'G', // Government
      'H', // Hindu Undivided Family
      'J', // Artificial Juridical Person
      'L', // Local Authority
      'P', // Individual/Person
      'T', // Trust
    };
    if (!validHolderTypes.contains(normalized[3])) return false;

    // The numeric part must not be 0000
    final numericPart = normalized.substring(5, 9);
    if (numericPart == '0000') return false;

    return true;
  }

  static bool isValidAadhaar(String value) => _isValidAadhaar(value);

  static bool isValidPan(String value) => _isValidPan(value);
}

class _VerificationResult {
  const _VerificationResult({
    required this.confirmed,
    required this.code,
    required this.aadhaarNumber,
    required this.panNumber,
    required this.policeCertificate,
  });

  final bool confirmed;
  final String code;
  final String aadhaarNumber;
  final String panNumber;
  final XFile? policeCertificate;
}
