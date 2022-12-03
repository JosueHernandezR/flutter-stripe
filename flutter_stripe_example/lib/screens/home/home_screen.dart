import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../../.env';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: const Text('Metodo de pago con Stripe'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Center(
                child: PaymentButton(),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentButton extends StatefulWidget {
  const PaymentButton({
    Key? key,
  }) : super(key: key);

  @override
  State<PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends State<PaymentButton> {
  Map<String, dynamic>? paymentIntentData;
  final client = http.Client();
  static Map<String, String> headers = {
    'Authorization': 'Bearer $stripePrivateKey',
    'Content-Type': 'application/x-www-form-urlencoded'
  };
  String money = 10.toString();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        makePayment();
      },
      child: const Text('Pago con Stripe'),
    );
  }

  Future<Map<String, dynamic>> createPaymentIntent(
    String amount,
    String currency,
  ) async {
    const String url = 'https://api.stripe.com/v1/payment_intents';
    Map<String, dynamic> body = {
      'amount': calculateAmount(amount),
      'currency': currency,
      'payment_method_types[]': 'card'
    };
    try {
      var response =
          await http.post(Uri.parse(url), body: body, headers: headers);
      if (response.statusCode == 200) {
        debugPrint('CreatePaymentIntent success: ${response.body}');
        return json.decode(response.body);
      } else {
        debugPrint(json.decode('CreatePaymentIntent failed: ${response.body}'));
        throw 'Failed to create PaymentIntents.';
      }
    } catch (err) {
      throw 'Failed to create PaymentIntents.';
    }
  }

  payFee() {
    // try {
    //   if (kDebugMode) {
    //     print('database');
    //   }
    //   // User? user = FirebaseAuth.instance.currentUser;
    //   FirebaseFirestore.instance.collection('register users').doc().set({
    //     'uid': user!.uid,
    //   });
    //   Navigator.pop(context);
    //   Fluttertoast.showToast(msg: 'Registration Done');
    // } catch (e) {
    //   Fluttertoast.showToast(msg: e.toString());
    // }
  }

  Future<void> makePayment() async {
    try {
      paymentIntentData =
          await createPaymentIntent(money, 'MXN'); //json.decode(response.body);
      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              style: ThemeMode.dark,
              merchantDisplayName: 'ADH',
            ),
          )
          .then((value) {});
      displayPaymentSheet();
    } catch (e, s) {
      debugPrint('$e $s');
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((newValue) {
        payFee();
        debugPrint(
            'Funcionalidad de displayPaymentSheet: ${paymentIntentData.toString()}');
        paymentIntentData = null;
      }).onError((error, stackTrace) {
        debugPrint('Exception/DISPLAYPAYMENTSHEET==> $error $stackTrace');
      });
    } on StripeException catch (e) {
      debugPrint(e.toString());

      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text("Cancelled "),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  calculateAmount(String amount) {
    final a = (int.parse(amount)) * 100;
    return a.toString();
  }
}
