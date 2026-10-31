
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = 'YOUR_API_KEY';
  static const String model = 'gemini-2.5-flash';

  static Future<String> askAI(String question) async {
    if (apiKey == 'YOUR_API_KEY' || apiKey.isEmpty) {
      return 'Error: Please configure your Gemini API key.';
    }

    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    ).replace(
      queryParameters: {'key': apiKey},
    );

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {
                    'text': '''
You are Campus Digital Twin AI, a smart college assistant.

Help students with:
- Academics and coding
- Campus navigation
- Timetables and attendance
- Library services
- College-related questions

Instructions:
- Introduce yourself as Campus Digital Twin AI when appropriate.
- Give clear, accurate, student-friendly answers.
- Never invent college-specific information.
- If college data is unavailable, explain that clearly.
- Use simple English unless the student requests another language.
''',
                  },
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': question},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 1024,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final candidates = data['candidates'];

        if (candidates is List && candidates.isNotEmpty) {
          final content = candidates.first['content'];
          final parts = content?['parts'];

          if (parts is List) {
            final answer = parts
                .where(
                  (part) =>
                      part is Map<String, dynamic> &&
                      part['text'] is String,
                )
                .map((part) => part['text'] as String)
                .join('\n')
                .trim();

            if (answer.isNotEmpty) {
              return answer;
            }
          }
        }

        return 'The AI did not return a text response. Please try again.';
      }

      final error = data['error'];
      final message = error is Map
          ? error['message']?.toString() ?? 'Unknown API error'
          : 'Unknown API error';

      return 'API Error (${response.statusCode}): $message';
    } on FormatException {
      return 'Error: Invalid response received from the AI server.';
    } on http.ClientException {
      return 'Network error: Please check your internet connection.';
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }

      return 'Something went wrong. Please try again.';
    }
  }
}
