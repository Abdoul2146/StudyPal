import 'dart:convert';
import 'package:http/http.dart' as http;

class AiTutorService {
  final String apiKey;
  AiTutorService(this.apiKey);

  Future<String> ask(List<Map<String, String>> messages) async {
    const modelName = 'gemini-1.5-flash';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    final contents =
        messages.map((msg) {
          return {
            "role": msg['role'], // <-- REQUIRED for Gemini API
            "parts": [
              {"text": msg['text'] ?? ''},
            ],
          };
        }).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"contents": contents}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          "No response.";
    } else {
      return "Error: ${response.body}";
    }
  }
}
