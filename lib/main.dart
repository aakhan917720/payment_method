import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = "pk_test_51Tm9hH3wcQvNiep0bdIPA0P56IAJiQIAjchSxC6iOf6XB4hbZEAV8c9C5ULH6h995knCmvk4lpxTqbtsAOBccVm100p46kNEZe";
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const PaymentPage();
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool loading = false;
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.10:4242'));

  Future<void> makepayment() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await dio.post("/create-payment-intent", data: {
        'amount': 1000,
        'currency': 'usd',
      });

      if (response.statusCode != 200) {
        throw Exception("Server error : ${response.data}");
      }

      final clientSecret = response.data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "Your Company Name",
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Success")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: makepayment,
          child: const Text("Pay \$10"),
        ),
      ),
    );
  }
}








// return Scaffold(
//   // appBar: AppBar(title: Text("Stripe Payment Method", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),),
//   //   backgroundColor: Colors.blue, centerTitle: true,),
//   body: Center(
//     child: ElevatedButton(
//         onPressed: (makepayment),
//         child: Text("Payment")
//     ),
//   ),
// );











//
// Future<void> makepayment() async{
//   try{
//     await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: "",
//           merchantDisplayName: "Amplitude",
//           style: ThemeMode.dark,
//         ),);
//     await Stripe.instance.presentCustomerSheet();
//     print("Payment Sucecssful");
//   }catch(e){
//     print("Payment failed $e");
//   }
// }