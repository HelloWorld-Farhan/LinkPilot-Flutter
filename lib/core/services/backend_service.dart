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

    try {
      // Google Apps Script returns 302 redirects on POST.
      // We must manually follow redirects to preserve the POST body.
      final client = http.Client();
      String? responseBody;

      try {
        var targetUri = Uri.parse(_gasUrl);

        for (int attempt = 0; attempt < 6; attempt++) {
          final request = http.Request('POST', targetUri)
            ..headers.addAll(headers)
            ..followRedirects = false
            ..body = payload;

          final streamed = await client.send(request);
          final response = await http.Response.fromStream(streamed);

          // Follow redirect manually (preserving POST body)
          if (response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 303 ||
              response.statusCode == 307 ||
              response.statusCode == 308) {
            final location = response.headers['location'];
            if (location != null && location.isNotEmpty) {
              targetUri = Uri.parse(location);
              continue; // follow redirect
            }
          }

          // We got a real response
          responseBody = response.body;
          break;
        }
      } finally {
        client.close();
      }

      if (responseBody == null || responseBody.isEmpty) {
        return {'success': false, 'error': 'No response from server. Please check your Apps Script deployment.'};
      }

      final trimmed = responseBody.trim();

      // If still HTML, give a clear actionable error
      if (trimmed.startsWith('<')) {
        return {
          'success': false,
          'error':
              'Deployment error: Go to script.google.com → Deploy → Manage deployments → ensure "Execute as: Me" and "Who has access: Anyone (not just Google users)".'
        };
      }

      return jsonDecode(trimmed);
    } catch (e) {
      return {'success': false, 'error': 'Connection error: ${e.toString()}'};
    }
  }
}
