import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String _cloudFunctionUrl =
      'https://us-central1-YOUR-ACTUAL-PROJECT-ID.cloudfunctions.net/createPaymentIntent';

  static Future<Map<String, dynamic>> createPaymentIntent({
    required String amount,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed: ${response.body}');
      }

    } catch (e) {
      throw Exception('Payment Error: $e');
    }
  }
}