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

  final response = await http.post(
    Uri.parse('https://script.google.com/macros/s/AKfycbx6ey8v-VNnWZSe0Kdf1NGlK-drRpDY2Vsv73v9B__ZvjmwZ3HY1jf_bv_j4uiWlTXB/exec'),
    headers: {'Content-Type': 'application/json'},
    body: payload,
  );
  print(response.statusCode);
  print(response.body);
}
