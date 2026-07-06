import 'package:flutter/material.dart';

class StripeCheckoutScreen extends StatefulWidget {
  const StripeCheckoutScreen({super.key});

  @override
  State<StripeCheckoutScreen> createState() => _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends State<StripeCheckoutScreen> {
  bool isLoading = false;

  // انپٹ فیلڈز کے کنٹرولرز
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();

  // ─── پریکٹس کے لیے فرضی پیمنٹ فنکشن (بغیر ٹوکن کے) ──────────────────────────
  Future<void> simulatePayment() async {
    // 1. ویلیڈیشن چیک کریں کہ کوئی فیلڈ خالی نہ ہو
    if (_nameController.text.trim().isEmpty ||
        _cardNumberController.text.trim().isEmpty ||
        _expiryController.text.trim().isEmpty ||
        _cvcController.text.trim().isEmpty) {
      _showSnackBar("Please fill all card details", Colors.orange);
      return;
    }

    setState(() { isLoading = true; });

    // 2. اصل ایپ کی طرح 2 سیکنڈ کی لوڈنگ دکھائیں
    await Future.delayed(const Duration(seconds: 2));

    setState(() { isLoading = false; });

    // 3. کامیابی کا میسج دکھائیں اور پہلی اسکرین پر واپس جائیں
    _showSnackBar("Payment Successful (Practice Mode)!", Colors.green);
    if (mounted) Navigator.pop(context);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Enter Card Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 15),
            Text("Connecting with Stripe...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. کارڈ ہولڈر کا نام
            const Text('Cardholder Name', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTextField(_nameController, "e.g. Abdul Ahad", Icons.person_outline, TextInputType.name),
            const SizedBox(height: 20),

            // 2. کارڈ نمبر
            const Text('Card Number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTextField(_cardNumberController, "4242 4242 4242 4242", Icons.credit_card, TextInputType.number),
            const SizedBox(height: 20),

            // 3. ایکسپائری اور CVC (ایک ہی لائن میں)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expiry Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField(_expiryController, "MM/YY", Icons.calendar_today_outlined, TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CVC', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField(_cvcController, "123", Icons.lock_outline, TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 4. پے کرنے کا بٹن
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: simulatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ٹیکسٹ فیلڈز بنانے کا آسان کسٹم وزٹ
  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}