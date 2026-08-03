import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  static const String _gasUrl =
      'https://script.google.com/macros/s/AKfycbx6ey8v-VNnWZSe0Kdf1NGlK-drRpDY2Vsv73v9B__ZvjmwZ3HY1jf_bv_j4uiWlTXB/exec';
  static const String senderEmail = 'linkpilot.support@gmail.com';

  static Future<Map<String, dynamic>> generateAndProcess({
    required String reportName,
    required String recipientEmail,
    required bool sendEmail,
    required List<Map<String, String>> links,
  }) async {
    final payload = jsonEncode({
      'reportName': reportName,
      'senderEmail': senderEmail,
      'recipientEmail': recipientEmail,
      'sendEmail': sendEmail,
      'links': links,
    });

    final headers = {
      'Content-Type': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
    };

    final client = http.Client();
    try {
      // Step 1: POST to GAS - do NOT follow redirects
      final postRequest = http.Request('POST', Uri.parse(_gasUrl))
        ..headers.addAll(headers)
        ..followRedirects = false
        ..body = payload;

      final postStreamed = await client.send(postRequest);
      final postResponse = await http.Response.fromStream(postStreamed);

      String? responseBody;

      // Step 2: GAS always returns 302. Follow the redirect as GET (RFC 7231 standard)
      if (postResponse.statusCode >= 300 && postResponse.statusCode < 400) {
        final location = postResponse.headers['location'];
        if (location != null && location.isNotEmpty) {
          // Follow redirect as GET — this is how browsers handle 302 from POST
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
        // Direct response (no redirect)
        responseBody = postResponse.body;
      }

      if (responseBody == null || responseBody.trim().isEmpty) {
        return {
          'success': false,
          'error': 'No response from server. Check Apps Script deployment settings.'
        };
      }

      final trimmed = responseBody.trim();

      // If JSON found anywhere in the response, extract it
      final jsonStart = trimmed.indexOf('{');
      final jsonEnd = trimmed.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        try {
          final extracted = trimmed.substring(jsonStart, jsonEnd + 1);
          return jsonDecode(extracted);
        } catch (_) {
          // fall through
        }
      }

      if (trimmed.startsWith('<')) {
        String snippet = trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;
        return {
          'success': false,
          'error': 'Server returned HTML instead of JSON: $snippet'
        };
      }

      return jsonDecode(trimmed);
    } catch (e) {
      return {'success': false, 'error': 'Connection error: ${e.toString()}'};
    } finally {
      client.close();
    }
  }
}
