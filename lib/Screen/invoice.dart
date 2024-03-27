import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../Model/Cart_Model.dart';
import '../Model/address_Model.dart';

class InvoiceScreen extends StatefulWidget {
  final String add_id;
  final List<Cart_Model> cartList;

  const InvoiceScreen({Key? key, required this.add_id, required this.cartList})
      : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Razorpay _razorpay = Razorpay();
  String userContact = ''; // Variable to store user's contact number

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    getUserContact();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment successful, handle the success logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful')),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Payment failed, handle the failure logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Failed')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void openCheckout() {
    var options = {
      'key': 'rzp_test_nLQYAWuOKvzENb',
      'amount': calculateGrandTotal() * 100,
      'name': 'Unicorn',
      'description': "Payment of Your Order",
      'prefill': {
        'contact': userContact,
        'email': FirebaseAuth.instance.currentUser!.email.toString(),
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: $e');
    }
  }

  double calculateGrandTotal() {
    double grandTotal = 0;
    for (var cart in widget.cartList) {
      grandTotal += double.parse(cart.price_new) * double.parse(cart.qty);
    }
    if (grandTotal < 10000) {
      grandTotal += 50;
    }
    return grandTotal;
  }

  // Function to retrieve user's contact number from Firestore
  void getUserContact() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('Customeraddress')
        .where("Uid", isEqualTo: uid)
        .get();
    if (userSnapshot.docs.isNotEmpty) {
      setState(() {
        userContact = userSnapshot.docs[0][
            'contact']; // Assuming 'contact' is the field name for contact number in Firestore
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice"),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Customeraddress")
            .where("add_id", isEqualTo: widget.add_id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else {
            final List<Address_Model> addresses = snapshot.data!.docs
                .map((doc) => Address_Model.fromFirestore(doc))
                .toList();

            return ListView.builder(
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                var address = addresses[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "User Address:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(address.fullname),
                    ),
                    ListTile(
                      title: Text(address.phoneno),
                    ),
                    ListTile(
                      title: Text(address.houseno),
                    ),
                    ListTile(
                      title: Text(address.roadname),
                    ),
                    ListTile(
                      title: Text(address.city),
                    ),
                    ListTile(
                      title: Text(address.state),
                    ),
                    ListTile(
                      title: Text(address.country),
                    ),
                    ListTile(
                      title: Text(address.pincode),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Order Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Column(
                      children: widget.cartList.map((cartItem) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(cartItem.product_name),
                            subtitle: Text(
                                "Price: ${cartItem.price_new}, Qty: ${cartItem.qty}"),
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Grand Total",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            " ₹${calculateGrandTotal().toString()}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cash on Delivery')),
                          );
                        },
                        child: const Text(
                          "Cash on Delivery",
                          style: TextStyle(fontSize: 20, color: Colors.indigo),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          openCheckout();
                        },
                        child: const Text(
                          "Pay with Razorpay",
                          style: TextStyle(fontSize: 20, color: Colors.indigo),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
