import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const apiKey = 'LhLJSLVlUHlphs6tNXzIeRz4vwDjWIiQ';

  static Future<String> sendMessage(String message) async {
    final url = Uri.parse(
      'https://factchat-cloud.mindlogic.ai/v1/gateway/chat/completions/',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "claude-sonnet-4-6",
        "messages": [
          {"role": "user", "content": message},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(response.body);
    }
  }
}
