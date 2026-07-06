import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:payment_methoed/screens/stripecheckoutscreen.dart';

import 'NoWebhookPaymentCardFormScreen.dart';
import 'NoWebhookPaymentScreen.dart';
import 'WebhookPaymentScreen.dart';
import 'custompaymentcard.dart'; // انٹرنیٹ سے ٹوکن لانے کے لیے

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedMethod = 'card';
  bool isLoading = false;
  Map<String, dynamic>? paymentIntentData;

  // ─── پریکٹس کے لیے ٹوکن لانے اور پیمنٹ شیٹ کھولنے کا فنکشن ──────────────────
  Future<void> makePracticePayment() async {
    setState(() { isLoading = true; });

    try {
      // 1. اسٹرائپ کے ٹیسٹ سرور سے رابطہ کر کے ٹوکن (Client Secret) مانگنا
      // ہم ٹیسٹنگ کے لیے $10 (1000 Cents) کا آرڈر بنا رہے ہیں
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intent_examples'),
        /*
           نوٹ: یہ اسٹرائپ کا آفیشل پریکٹس اینڈ پوائنٹ ہے جو ڈویلپرز کو
           بغیر بیک اینڈ کے ٹیسٹنگ کے لیے عارضی کلاؤنٹ سیکریٹ فراہم کرتا ہے۔
        */
      );

      if (response.statusCode == 200) {
        paymentIntentData = jsonDecode(response.body);

        // 2. سرور سے ملنے والے ٹوکن کو اسٹرائپ وزٹ میں ڈالنا
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentData!['client_secret'], // یہاں ٹوکن خود بخود آ گیا!
            merchantDisplayName: 'Ahad Practice App',
            style: ThemeMode.light,
          ),
        );

        // 3. اب موبائل پر کارڈ والا خوبصورت فارم کھولنا
        await Stripe.instance.presentPaymentSheet();

        // اگر کارڈ نمبر صحیح ڈالا اور پیمنٹ ہو گئی
        _showSnackBar("Practice Payment Successful!", Colors.green);
      } else {
        _showSnackBar("Failed to get token from Stripe Test Server", Colors.red);
      }

    } catch (e) {
      if (e is StripeException) {
        _showSnackBar("Stripe Error: ${e.error.localizedMessage}", Colors.red);
      } else {
        _showSnackBar("Error: $e", Colors.red);
      }
    } finally {
      setState(() { isLoading = false; });
    }
  }
  // ──────────────────────────────────────────────────────────────────────

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Stripe Practice UI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Amount', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 5),
                  Text('\$ 10.00', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _buildPaymentOption(
              id: 'card',
              title: 'Credit / Debit Card',
              subtitle: 'Open Stripe Test Form',
              icon: Icons.credit_card,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              id: 'google_pay',
              title: 'Google Pay',
              subtitle: 'Not available in practice mode',
              icon: Icons.phone_android,
              iconColor: Colors.grey,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedMethod == 'card') {
                    makePracticePayment(); // پریکٹس فنکشن کال ہوگا
                  } else {
                    _showSnackBar("Select Credit Card for practice.", Colors.orange);
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context)=>NoWebhookPaymentScreen(),
                    ),
                  );

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Open Payment Sheet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    bool isSelected = selectedMethod == id;
    return GestureDetector(
      onTap: () {
        if (id == 'card') {
          setState(() { selectedMethod = id; });
        } else {
          _showSnackBar("Only Credit Card works in practice mode without server.", Colors.blue);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.indigo : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Colors.indigo : Colors.grey),
          ],
        ),
      ),
    );
  }
}