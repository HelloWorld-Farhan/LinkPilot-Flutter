import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  static const String _gasUrl = 'https://script.google.com/macros/s/AKfycbyoLOqYiRRz9xFdR3ao4hKJki2X7phw4_jBuM6cwikYSZN8F39S9tNaDwj3PUHvKrLv/exec';

  static Future<Map<String, dynamic>> generateAndProcess({
    required String reportName,
    required String recipientEmail,
    required bool sendEmail,
    required List<Map<String, String>> links,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_gasUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reportName': reportName,
          'senderEmail': recipientEmail, // Google Apps Script still looks for senderEmail in the old code, wait, let's just pass both so we don't break the old variable in GAS if they didn't update the variable name. I'll pass 'recipientEmail' and 'senderEmail'.
          'recipientEmail': recipientEmail,
          'sendEmail': sendEmail,
          'links': links,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        // Apps Script often returns 302 redirects which http package handles automatically,
        // but if it returns the JSON directly it will be 200.
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
