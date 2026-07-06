import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;

// پریکٹس کے لیے فرضی API URL تاکہ kApiUrl والا ایرر ختم ہو جائے
const String kApiUrl = 'https://api.example.com';

class WebhookPaymentScreen extends StatefulWidget {
  const WebhookPaymentScreen({super.key});

  @override
  _WebhookPaymentScreenState createState() => _WebhookPaymentScreenState();
}

class _WebhookPaymentScreenState extends State<WebhookPaymentScreen> {
  CardFieldInputDetails? _card;
  String _email = 'email@stripe.com';
  bool? _saveCard = false;
  bool isButtonLoading = false; // لوڈنگ اسٹیٹ کو مینیج کرنے کے لیے

  @override
  Widget build(BuildContext context) {
    // ExampleScaffold کو Flutter کے آفیشل Scaffold سے تبدیل کر دیا گیا ہے
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Field'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(hintText: 'Email', labelText: 'Email'),
              onChanged: (value) {
                setState(() {
                  _email = value;
                });
              },
            ),
            const SizedBox(height: 20),
            CardField(
              preferredNetworks: const [CardBrand.Visa],
              enablePostalCode: true,
              countryCode: 'US',
              postalCodeHintText: 'Enter the us postal code',
              onCardChanged: (card) {
                setState(() {
                  _card = card;
                });
              },
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _saveCard,
              onChanged: (value) {
                setState(() {
                  _saveCard = value;
                });
              },
              title: const Text('Save card during payment'),
            ),
            const SizedBox(height: 20),

            // LoadingButton کو فکسڈ ElevatedButton سے بدل دیا گیا ہے
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _card?.complete == true && !isButtonLoading ? _handlePayPress : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isButtonLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Pay', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            // ResponseCard کو عام Card اور کسٹم کوڈ فارمیٹ سے بدل دیا گیا ہے
            if (_card != null)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    // toPrettyString() کا ایرر ختم کرنے کے لیے json.encode استعمال کیا ہے
                    json.encode(_card!.toJson()),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayPress() async {
    if (_card == null) {
      return;
    }

    setState(() { isButtonLoading = true; });
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. fetch Intent Client Secret from backend
      final clientSecret = await fetchPaymentIntentClientSecret();

      // 2. Gather customer billing information (ex. email)
      const billingDetails = BillingDetails(
        email: 'email@stripe.com',
        phone: '+48888000888',
        address: Address(
          city: 'Houston',
          country: 'US',
          line1: '1459 Circle Drive',
          line2: '',
          state: 'Texas',
          postalCode: '77063',
        ),
      );

      // 3. Confirm payment with card details
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret['clientSecret'],
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
        options: PaymentMethodOptions(
          setupFutureUsage:
          _saveCard == true ? PaymentIntentsFutureUsage.OffSession : null,
        ),
      );

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text('Success!: The payment was confirmed successfully!')));
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() { isButtonLoading = false; });
    }
  }

  Future<Map<String, dynamic>> fetchPaymentIntentClientSecret() async {
    final url = Uri.parse('$kApiUrl/create-payment-intent');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'currency': 'usd',
        'amount': 1099,
        'payment_method_types': ['card'],
        'request_three_d_secure': 'any',
      }),
    );
    return json.decode(response.body);
  }
}