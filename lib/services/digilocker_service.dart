import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
      // 1. Launch the actual DigiLocker URL if a real client ID is provided.
      // If using the placeholder, skip to the simulation dialog to avoid 400 errors.
      if (_clientId != 'DEMO_CLIENT_ID') {
        await launchDigiLockerLogin();
      } else {
        debugPrint(
          'DigiLocker: Using placeholder DEMO_CLIENT_ID. Skipping actual URL launch and proceeding to simulation.',
        );
      }

      if (!context.mounted) return false;

      // 2. Simulate the redirect capture using a Dialog for educational purposes.
      // In a real app, this would be captured by app_links / uni_links package automatically.
      final result = await _showSimulatedRedirectDialog(context);

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
          docs.contains(_docPolice);

      if (hasRequiredDocs) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('DigiLocker verification failed: $e');
      return false;
    }
  }

  static Future<_SimulatedVerificationResult?> _showSimulatedRedirectDialog(
    BuildContext context,
  ) {
    bool aadhaar = true;
    bool pan = true;
    bool police = true;

    return showDialog<_SimulatedVerificationResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Verify Required Documents'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please confirm DigiLocker authentication and available documents:',
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: aadhaar,
                    onChanged: (value) {
                      setModalState(() => aadhaar = value ?? false);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(_docAadhaar),
                  ),
                  CheckboxListTile(
                    value: pan,
                    onChanged: (value) {
                      setModalState(() => pan = value ?? false);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(_docPan),
                  ),
                  CheckboxListTile(
                    value: police,
                    onChanged: (value) {
                      setModalState(() => police = value ?? false);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(_docPolice),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      ctx,
                      _SimulatedVerificationResult(
                        confirmed: aadhaar && pan && police,
                        code: 'sample_auth_code_${Random().nextInt(99999)}',
                      ),
                    );
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SimulatedVerificationResult {
  const _SimulatedVerificationResult({
    required this.confirmed,
    required this.code,
  });

  final bool confirmed;
  final String code;
}
