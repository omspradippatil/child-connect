import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  GeminiService._();

  static String? get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['API_KEY'];
    if (key == null || key.trim().isEmpty) {
      return null;
    }
    return key.trim();
  }

  static bool get isConfigured => _apiKey != null;

  static Future<String?> generateSupportResponse({
    required String userMessage,
    required List<Map<String, dynamic>> children,
    required List<Map<String, dynamic>> programs,
    required List<Map<String, dynamic>> adoptionSteps,
    required List<Map<String, dynamic>> missionPoints,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      return null;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final prompt = _buildPrompt(
      userMessage: userMessage,
      children: children,
      programs: programs,
      adoptionSteps: adoptionSteps,
      missionPoints: missionPoints,
    );

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.5, 'maxOutputTokens': 250},
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final first = candidates.first;
    if (first is! Map) {
      return null;
    }

    final content = first['content'];
    if (content is! Map) {
      return null;
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      return null;
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(part['text'] as String);
      }
    }

    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _buildPrompt({
    required String userMessage,
    required List<Map<String, dynamic>> children,
    required List<Map<String, dynamic>> programs,
    required List<Map<String, dynamic>> adoptionSteps,
    required List<Map<String, dynamic>> missionPoints,
  }) {
    final childSummary = children
        .take(6)
        .map(
          (child) =>
              '- ${child['name'] ?? ''}, age ${child['age'] ?? ''}, location ${child['location'] ?? ''}, interests ${child['interests'] ?? ''}',
        )
        .join('\n');
    final programSummary = programs
        .take(6)
        .map(
          (program) =>
              '- ${program['title'] ?? ''}: ${program['description'] ?? ''}',
        )
        .join('\n');
    final adoptionSummary = adoptionSteps
        .take(6)
        .map(
          (step) =>
              '- ${step['step'] ?? ''} ${step['title'] ?? ''}: ${step['description'] ?? ''}',
        )
        .join('\n');
    final missionSummary = missionPoints
        .take(4)
        .map(
          (point) => '- ${point['title'] ?? ''}: ${point['description'] ?? ''}',
        )
        .join('\n');

    return '''You are the Child Connect assistant for an adoption and mentoring support app.
Answer the user's question using the app context below.
Keep the answer practical, short, and clear.
If the question is unrelated to Child Connect, redirect politely back to adoption, children, mentoring, programs, or support topics.
Do not invent legal claims or sensitive personal data.

Available children:
$childSummary

Programs:
$programSummary

Adoption steps:
$adoptionSummary

Mission and support:
$missionSummary

User question:
$userMessage''';
  }
}
