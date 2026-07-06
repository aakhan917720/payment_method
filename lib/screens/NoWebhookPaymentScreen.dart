import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
const String kApiUrl = 'https://api.example.com';

class NoWebhookPaymentScreen extends StatefulWidget {
  const NoWebhookPaymentScreen({super.key});

  @override
  _NoWebhookPaymentScreenState createState() => _NoWebhookPaymentScreenState();
}

class _NoWebhookPaymentScreenState extends State<NoWebhookPaymentScreen> {
  final controller = CardEditController();
  bool isButtonLoading = false; // لوڈنگ اسٹیٹ مینیج کرنے کے لیے

  @override
  void initState() {
    controller.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(update);
    controller.dispose();
    super.dispose();
  }

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
          children: [
            CardField(
                controller: controller,
                numberHintText: '34556689232'
            ),
            const SizedBox(height: 20),

            // LoadingButton کی جگہ فکسڈ ElevatedButton جو لوڈنگ اینیمیشن بھی سنبھالے گا
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.complete && !isButtonLoading ? _handlePayPress : null,
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
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => controller.focus(),
                    child: const Text('Focus'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => controller.blur(),
                    child: const Text('Blur'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => controller.clear(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 20),

            // ResponseCard کو عام Card ویجٹ سے تبدیل کر دیا گیا ہے
            Card(
              margin: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  // toPrettyString() کا ایرر ختم کرنے کے لیے json.encode استعمال کیا ہے
                  json.encode(controller.details.toJson()),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayPress() async {
    if (!controller.complete) {
      return;
    }

    setState(() { isButtonLoading = true; });
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Gather customer billing information (ex. email)
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

      // 2. Create payment method
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(billingDetails: billingDetails),
        ),
      );

      // 3. call API to create PaymentIntent
      final paymentIntentResult = await callNoWebhookPayEndpointMethodId(
        useStripeSdk: true,
        paymentMethodId: paymentMethod.id,
        currency: 'usd',
        items: ['id-1'],
      );

      if (paymentIntentResult['error'] != null) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error: ${paymentIntentResult['error']}')),
          );
        }
        return;
      }

      if (paymentIntentResult['clientSecret'] != null &&
          paymentIntentResult['requiresAction'] == null &&
          context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Success!: The payment was confirmed successfully!'),
          ),
        );
        return;
      }

      if (paymentIntentResult['clientSecret'] != null &&
          paymentIntentResult['requiresAction'] == true) {
        // 4. if payment requires action calling handleNextAction
        final paymentIntent = await Stripe.instance.handleNextAction(
          paymentIntentResult['clientSecret'],
          returnURL: 'flutterstripe://redirect',
        );

        if (paymentIntent.status == PaymentIntentsStatus.RequiresConfirmation) {
          // 5. Call API to confirm intent
          await confirmIntent(paymentIntent.id);
        } else {
          if (context.mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('Error: ${paymentIntentResult['error']}')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() { isButtonLoading = false; });
    }
  }

  Future<void> confirmIntent(String paymentIntentId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final result = await callNoWebhookPayEndpointIntentId(
        paymentIntentId: paymentIntentId,
      );
      if (result['error'] != null && context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}')),
        );
      } else {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Success!: The payment was confirmed successfully!'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<Map<String, dynamic>> callNoWebhookPayEndpointIntentId({
    required String paymentIntentId,
  }) async {
    final url = Uri.parse('$kApiUrl/charge-card-off-session');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'paymentIntentId': paymentIntentId}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> callNoWebhookPayEndpointMethodId({
    required bool useStripeSdk,
    required String paymentMethodId,
    required String currency,
    List<String>? items,
  }) async {
    final url = Uri.parse('$kApiUrl/pay-without-webhooks');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'useStripeSdk': useStripeSdk,
        'paymentMethodId': paymentMethodId,
        'currency': currency,
        'items': items,
      }),
    );
    return json.decode(response.body);
  }
}