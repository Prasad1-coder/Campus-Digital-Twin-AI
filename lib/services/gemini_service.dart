import 'dart:convert';
import 'package:http/http.dart' as http;


class GeminiService {
  static const String apiKey = "AQ.Ab8RN6IDPUSVAcK_vpXzkGuxKni2j5H7hEqt8Z9VXeWPj7xA4w";

  static Future<String> askAI(String question) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
  "contents": [
    {
      "parts": [
        {
          "text":
              "You are Campus Digital Twin AI, a smart college assistant. Always introduce yourself as Campus Digital Twin AI. Help students with academics, campus navigation, timetable, attendance, library, coding, and college-related questions.\n\nUser: $question"
        }
      ]
    }
  ]
}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "Error: ${response.body}";
    }
  }
}