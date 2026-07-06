import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'screens/payment_screen.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = 'pk_test_51Tm9iI46kaApcreV8gZkQazQJBK7abdRh2I4uRsDPh5BUIl5sjJZ7zK5hqiMxZisD7GBhm5Ss4yVxifqx12wyMoD000iJFfcQR';

  await Stripe.instance.applySettings();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stripe Payment',
      home: PaymentScreen(),
    );
  }
}