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
            "role": msg['role'],
            "parts": [
              {
                "text": msg['text'] ?? msg['content'] ?? '',
              }, // Handle both text and content keys
            ],
          };
        }).toList();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"contents": contents}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text == null) throw Exception('No valid response from API');
        return text;
      } else {
        throw Exception('API Error: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to communicate with Gemini: $e');
    }
  }
}

Future<List<Map<String, String>>> fetchYoutubeVideos(
  String query,
  String apiKey,
) async {
  final url = Uri.parse(
    'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=3&q=${Uri.encodeComponent(query)}&key=$apiKey',
  );
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final items = data['items'] as List;
    return items
        .map((item) {
          final id = item['id']['videoId'].toString();
          final title = item['snippet']['title'].toString();
          final channel = item['snippet']['channelTitle'].toString();
          return {
            'url': 'https://www.youtube.com/watch?v=$id',
            'title': title,
            'channel': channel,
          };
        })
        .toList()
        .cast<Map<String, String>>();
  } else {
    return [];
  }
}
