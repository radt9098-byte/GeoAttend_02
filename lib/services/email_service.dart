import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // TODO: Replace these three placeholders with your real values from your
  // EmailJS dashboard (emailjs.com -> Email Services / Email Templates ->
  // Account -> General). These are safe to commit directly in code -
  // EmailJS's "public key" is designed to be embedded in client apps, the
  // same way it's used in browser-based JS integrations.
  static const String serviceId = 'EMAILJS_SERVICE_ID_PLACEHOLDER';
  static const String templateId = 'EMAILJS_TEMPLATE_ID_PLACEHOLDER';
  static const String publicKey = 'EMAILJS_PUBLIC_KEY_PLACEHOLDER';

  Future<bool> sendRecoveryEmail(String email, String newPin) async {
    if (serviceId.endsWith('_PLACEHOLDER') ||
        templateId.endsWith('_PLACEHOLDER') ||
        publicKey.endsWith('_PLACEHOLDER')) {
      throw Exception(
          'Email recovery is not configured yet. Edit lib/services/email_service.dart and fill in your real EmailJS Service ID, Template ID, and Public Key.');
    }

    const String url = 'https://api.emailjs.com/api/v1.0/email/send';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': email,
          'new_pin': newPin,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to send recovery email (status ${response.statusCode}). Check your internet connection and EmailJS setup.');
    }
    return true;
  }
}
