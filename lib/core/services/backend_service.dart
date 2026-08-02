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
    try {
      final response = await http.post(
        Uri.parse(_gasUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: jsonEncode({
          'reportName': reportName,
          'senderEmail': senderEmail,
          'recipientEmail': recipientEmail,
          'sendEmail': sendEmail,
          'links': links,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final body = response.body.trim();
        if (body.startsWith('<')) {
          return {
            'success': false,
            'error':
                'Server returned an HTML page. Please ensure your Google Apps Script is deployed with "Execute as: Me" and "Who has access: Anyone".',
          };
        }
        return jsonDecode(body);
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
