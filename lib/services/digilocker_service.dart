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

  /// Complete flow: Launches login, waits for user to manually confirm, then verifies.
  /// Used directly from the UI to encapsulate the verification logic.
  static Future<bool> verifyUserIdentity(
    BuildContext context, {
    required String aadhaarNumber,
    required String panNumber,
  }) async {
    try {
      if (!context.mounted) return false;

      final normalizedAadhaar = aadhaarNumber.replaceAll(RegExp(r'\s+'), '');
      final normalizedPan = panNumber.trim().toUpperCase();
      if (!isValidAadhaar(normalizedAadhaar) || !isValidPan(normalizedPan)) {
        return false;
      }

      // 2. Simulate the redirect capture using a Dialog for educational purposes.
      // In a real app, this would be captured by app_links / uni_links package automatically.
      final result = await _showVerificationForm(
        context,
        aadhaarNumber: normalizedAadhaar,
        panNumber: normalizedPan,
      );

      if (result == null || !result.confirmed || result.code.isEmpty) {
        return false; // User cancelled
      }

      // 3. Exchange code for token
      final token = await exchangeAuthCodeForToken(result.code);

      // 4. Fetch documents
      final docs = await fetchUserDocuments(token);

      // 5. Verify documents exist
      final hasRequiredDocs =
          docs.contains(_docAadhaar) &&
          docs.contains(_docPan) &&
          docs.contains(_docPolice) &&
          isValidAadhaar(result.aadhaarNumber) &&
          isValidPan(result.panNumber) &&
          result.policeCertificate != null;

      if (hasRequiredDocs) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('DigiLocker verification failed: $e');
      return false;
    }
  }

  static Future<_VerificationResult?> _showVerificationForm(
    BuildContext context, {
    required String aadhaarNumber,
    required String panNumber,
  }) {
    XFile? selectedCertificate;
    bool busy = false;

    return showModalBottomSheet<_VerificationResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
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
                if (file == null) {
                  return;
                }
                setModalState(() => selectedCertificate = file);
              } finally {
                setModalState(() => busy = false);
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DigiLocker Verification',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Complete identity verification with Aadhaar number, PAN number, and Police Clearance Certificate upload.',
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDE3F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KYC Details (From Sign In)',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text('Aadhaar: $aadhaarNumber'),
                              const SizedBox(height: 4),
                              Text('PAN: $panNumber'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDE3F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Police Clearance Certificate',
                                style: TextStyle(fontWeight: FontWeight.w700),
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
                                    future: selectedCertificate!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 160,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return const SizedBox(
                                          height: 160,
                                          child: Center(
                                            child: Text('Error loading image'),
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
                        const SizedBox(height: 18),
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
                                        if (selectedCertificate == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Upload the Police Clearance Certificate from gallery or camera.',
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
                                            aadhaarNumber: aadhaarNumber,
                                            panNumber: panNumber,
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
                                    : const Text('Verify And Continue'),
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
