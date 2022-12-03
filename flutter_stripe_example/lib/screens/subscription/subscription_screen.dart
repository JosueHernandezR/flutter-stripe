import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:http/http.dart' as http;
import '../../.env';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: SubscriptionButton(),
        ),
      ),
    );
  }
}

class SubscriptionButton extends StatefulWidget {
  const SubscriptionButton({
    Key? key,
  }) : super(key: key);

  @override
  State<SubscriptionButton> createState() => _SubscriptionButtonState();
}

class _SubscriptionButtonState extends State<SubscriptionButton> {
  final client = http.Client();
  static Map<String, String> headers = {
    'Authorization': 'Bearer $stripePrivateKey',
    'Content-Type': 'application/x-www-form-urlencoded'
  };

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Subscription'),
      onPressed: () {
        susbscription();
      },
    );
  }

  Future<Map<String, dynamic>> _createCustomer() async {
    const String url = 'https://api.stripe.com/v1/customers';
    var response = await client.post(
      Uri.parse(url),
      headers: headers,
      body: {'description': 'new customer'},
    );
    if (response.statusCode == 200) {
      debugPrint('Create Customer success: ${json.decode(response.body)}');

      return json.decode(response.body);
    } else {
      debugPrint('Create Customer error: ${json.decode(response.body)}');
      throw 'Failed to register as a customer.';
    }
  }

  Future<Map<String, dynamic>> _createPaymentMethod({
    required String number,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    const String url = 'https://api.stripe.com/v1/payment_methods';
    var response = await client.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'type': 'card',
        'card[number]': '$number',
        'card[exp_month]': '$expMonth',
        'card[exp_year]': '$expYear',
        'card[cvc]': '$cvc',
      },
    );
    if (response.statusCode == 200) {
      debugPrint('Payment method data success: ${response.body}');
      return json.decode(response.body);
    } else {
      debugPrint('Payment method data failed: ${response.body}');

      throw 'Failed to create PaymentMethod.';
    }
  }

  Future<Map<String, dynamic>> _attachPaymentMethod(
      String paymentMethodId, String customerId) async {
    final String url =
        'https://api.stripe.com/v1/payment_methods/$paymentMethodId/attach';
    var response = await client.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'customer': customerId,
      },
    );
    if (response.statusCode == 200) {
      debugPrint('Attach payment method success: ${response.body}');
      return json.decode(response.body);
    } else {
      debugPrint('Attach payment method failed: ${response.body}');
      throw 'Failed to attach PaymentMethod.';
    }
  }

  Future<Map<String, dynamic>> _updateCustomer(
      String paymentMethodId, String customerId) async {
    final String url = 'https://api.stripe.com/v1/customers/$customerId';

    var response = await client.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'invoice_settings[default_payment_method]': paymentMethodId,
      },
    );
    if (response.statusCode == 200) {
      debugPrint('Update Customer success: ${response.body}');
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      debugPrint('Update Customer failed: ${response.body}');

      throw 'Failed to update Customer.';
    }
  }

  Future<Map<String, dynamic>> _createSubscriptions(String customerId) async {
    const String url = 'https://api.stripe.com/v1/subscriptions';

    Map<String, dynamic> body = {
      'customer': customerId,
      'items[0][price]': 'price_1MAMk8Jm1CrLAEz5zpRtGlw4',
    };

    var response =
        await client.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 200) {
      debugPrint('Create subscription success: ${response.body}');

      return json.decode(response.body);
    } else {
      debugPrint('Create subscription failed: ${response.body}');

      print(json.decode(response.body));
      throw 'Failed to register as a subscriber.';
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance
          .presentPaymentSheet()
          .then((newValue) {})
          .onError((error, stackTrace) {
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

  Future<void> susbscription() async {
    final _customer = await _createCustomer();
    debugPrint('Creacion de customer: $_customer');
    final _paymentMethod = await _createPaymentMethod(
      number: '4242424242424242',
      expMonth: '03',
      expYear: '23',
      cvc: '123',
    );
    debugPrint('Data payment method: $_paymentMethod');
    final attachPaymentMethod = await _attachPaymentMethod(
      _paymentMethod['id'],
      _customer['id'],
    );
    debugPrint('Attach payment method: $attachPaymentMethod');

    final updateCustomer =
        await _updateCustomer(_paymentMethod['id'], _customer['id']);
    debugPrint('UpdateCustomer: $updateCustomer');

    final createSubscription = await _createSubscriptions(_customer['id']);
    debugPrint('CreateSubscription: $createSubscription');
  }
}
