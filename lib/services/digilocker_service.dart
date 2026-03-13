import 'dart:async';
import 'dart:io';
import 'dart:math';
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
  static Future<bool> verifyUserIdentity(BuildContext context) async {
    try {
      // 1. Launch the actual DigiLocker URL
      await launchDigiLockerLogin();

      if (!context.mounted) return false;

      // 2. Simulate the redirect capture using a Dialog for educational purposes.
      // In a real app, this would be captured by app_links / uni_links package automatically.
      final result = await _showVerificationForm(context);

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
          _isValidAadhaar(result.aadhaarNumber) &&
          _isValidPan(result.panNumber) &&
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
    BuildContext context,
  ) {
    final formKey = GlobalKey<FormState>();
    final aadhaarController = TextEditingController();
    final panController = TextEditingController();
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
                    key: formKey,
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
                            if (!_isValidAadhaar(value ?? '')) {
                              return 'Enter a valid 12-digit Aadhaar number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: panController,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: 'PAN Number',
                            hintText: 'Enter PAN number',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                          validator: (value) {
                            if (!_isValidPan(value ?? '')) {
                              return 'Enter a valid PAN number';
                            }
                            return null;
                          },
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
                              if (selectedCertificate != null &&
                                  !selectedCertificate!.path.startsWith(
                                    'http',
                                  ) &&
                                  File(
                                    selectedCertificate!.path,
                                  ).existsSync()) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(selectedCertificate!.path),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
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
                                        final isValid =
                                            formKey.currentState?.validate() ??
                                            false;
                                        if (!isValid) {
                                          return;
                                        }
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
                                            aadhaarNumber: aadhaarController
                                                .text
                                                .trim(),
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

  static bool _isValidAadhaar(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^\d{12}$').hasMatch(normalized);
  }

  static bool _isValidPan(String value) {
    final normalized = value.trim().toUpperCase();
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(normalized);
  }
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
