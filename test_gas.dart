import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final payload = jsonEncode({
    'reportName': 'Test',
    'senderEmail': 'linkpilot.support@gmail.com',
    'recipientEmail': 'test@example.com',
    'sendEmail': false,
    'links': [{'company': 'Google', 'url': 'https://google.com'}],
  });

  final headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  final client = http.Client();
  try {
    final postRequest = http.Request('POST', Uri.parse('https://script.google.com/macros/s/AKfycbx6ey8v-VNnWZSe0Kdf1NGlK-drRpDY2Vsv73v9B__ZvjmwZ3HY1jf_bv_j4uiWlTXB/exec'))
      ..headers.addAll(headers)
      ..followRedirects = false
      ..body = payload;

    final postStreamed = await client.send(postRequest);
    final postResponse = await http.Response.fromStream(postStreamed);

    String? responseBody;

    if (postResponse.statusCode >= 300 && postResponse.statusCode < 400) {
      final location = postResponse.headers['location'];
      if (location != null && location.isNotEmpty) {
        Uri redirectUri = Uri.parse(location);
        for (int i = 0; i < 5; i++) {
          final getRequest = http.Request('GET', redirectUri)
            ..headers['User-Agent'] = headers['User-Agent']!
            ..followRedirects = false;

          final getStreamed = await client.send(getRequest);
          final getResponse = await http.Response.fromStream(getStreamed);

          if (getResponse.statusCode >= 300 && getResponse.statusCode < 400) {
            final nextLocation = getResponse.headers['location'];
            if (nextLocation != null && nextLocation.isNotEmpty) {
              redirectUri = Uri.parse(nextLocation);
              continue;
            }
          }
          responseBody = getResponse.body;
          break;
        }
      }
    } else {
      responseBody = postResponse.body;
    }

    print('Response body: $responseBody');
  } finally {
    client.close();
  }
}
