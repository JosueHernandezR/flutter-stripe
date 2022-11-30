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

  // Primer paso: Registrar el customer en Stripe
  Future<Map<String, dynamic>> _createCustomer() async {
    const String url = 'https://api.stripe.com/v1/customers';
    var response = await client.post(
      Uri.parse(url),
      headers: headers,
      body: {'description': 'new customer'},
    );
    if (response.statusCode == 200) {
      debugPrint('CreateCustomer success: ${json.decode(response.body)}');

      return json.decode(response.body);
    } else {
      debugPrint('CreateCustomer failed: ${json.decode(response.body)}');

      throw 'Failed to register as a customer.';
    }
  }

  // Segundo paso: Crear intento de pago, agregadon el monto y la moneda
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

  // Tercer paso: Implementacion del formulario para llenar los campos de la
  // tarjeta de credito o debito para el usuario

  Future<void> createCreditCard(
      String customerId, String paymentIntentClientSecret) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        applePay: const PaymentSheetApplePay(merchantCountryCode: 'MEX'),
        googlePay: const PaymentSheetGooglePay(merchantCountryCode: 'MEX'),
        style: ThemeMode.dark,
        merchantDisplayName: 'Flutter Stripe Store Demo',
        customerId: customerId,
        paymentIntentClientSecret: paymentIntentClientSecret,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
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
              merchantDisplayName: 'ANNIE',
            ),
          )
          .then((value) {});
      displayPaymentSheet();
    } catch (e, s) {
      if (kDebugMode) {
        print(s);
      }
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

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((newValue) {
        payFee();

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
