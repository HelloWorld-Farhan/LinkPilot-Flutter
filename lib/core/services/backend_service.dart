import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  // TODO: Replace with the deployed Google Apps Script Web App URL
  static const String _gasUrl = 'YOUR_GOOGLE_APPS_SCRIPT_WEB_APP_URL';

  static Future<Map<String, dynamic>> generateAndSend(String senderEmail, List<Map<String, String>> links) async {
    try {
      final response = await http.post(
        Uri.parse(_gasUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderEmail': senderEmail,
          'links': links,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
