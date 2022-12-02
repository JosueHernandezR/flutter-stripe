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
      child: Text('Subscription'),
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
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to register as a customer.';
    }
  }

  Future<Map<String, dynamic>> _createPaymentMethod({
    required String number,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final String url = 'https://api.stripe.com/v1/payment_methods';
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
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
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
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
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
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to update Customer.';
    }
  }

  Future<Map<String, dynamic>> _createSubscriptions(String customerId) async {
    final String url = 'https://api.stripe.com/v1/subscriptions';

    Map<String, dynamic> body = {
      'customer': customerId,
      'items[0][price]': 'price_1MAMk8Jm1CrLAEz5zpRtGlw4',
    };

    var response =
        await client.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(json.decode(response.body));
      throw 'Failed to register as a subscriber.';
    }
  }

  Future<void> susbscription() async {
    final _customer = await _createCustomer();
    final _paymentMethod = await _createPaymentMethod(
        number: '4242424242424242', expMonth: '03', expYear: '23', cvc: '123');
    await _attachPaymentMethod(_paymentMethod['id'], _customer['id']);
    await _updateCustomer(_paymentMethod['id'], _customer['id']);
    await _createSubscriptions(_customer['id']);
  }
}
