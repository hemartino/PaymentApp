import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {
  static const Map<String, String> _testTokens = {
    '4242424242424242': 'tok_visa',
    '4000056655665556': 'tok_visa_debit',
    '5555555555554444': 'tok_mastercard',
    '5200828282828210': 'tok_mastercard_debit',
    '4000000000000002': 'tok_chargeDeclined',
    '4000000000009995': 'tok_chargeDeclinedInsufficientFunds',
  };

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = _testTokens[cleanCard];

    if (token == null) {
      return <String, dynamic>{
        'success': false,
        'error': 'unknown test card',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
        headers: <String, String>{
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'amount': amountInCentavos,
          'currency': 'php',
          'payment_method_types[]': 'card',
          'payment_method_data[type]': 'card',
          'payment_method_data[card][token]': token,
          'confirm': 'true',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;


      if (response.statusCode == 200 && (data['status'] == 'succeeded' || data['status'] == 'requires_capture')) {
        return <String, dynamic>{
          'success': true,
          'id': data['id'].toString(),
          'amount': (data['amount'] as num) / 100,
          'status': data['status'].toString(),
        };
      } else {
        final errorMsg = data['error'] is Map
            ? (data['error'] as Map)['message']?.toString() ?? 'payment failed'
            : 'payment failed';
        return <String, dynamic>{'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': e.toString(),
      };
    }
  }
}