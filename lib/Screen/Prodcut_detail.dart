import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:users/Screen/cart.dart';
import 'package:users/Screen/checkout.dart';

import '../Model/Product_Model.dart';

class ProductDetail extends StatefulWidget {
  final String productname;

  const ProductDetail({super.key, required this.productname});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  String qty = "1"; //dropdown
  List<String> options = ["1", "2", "3", "4", "5", "6"];
  var icon = const Icon(Icons.favorite_border);
  String buttonText = "Add to cart";
  bool isInCart = false;
  late Product_Model product;

  void getProductDetails() {
    FirebaseFirestore.instance
        .collection("Product")
        .where("product_name", isEqualTo: widget.productname)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final List<Product_Model> products = querySnapshot.docs
            .map((doc) => Product_Model.fromFirestore(
                doc as QueryDocumentSnapshot<Map<String, dynamic>>))
            .toList();
        setState(() {
          product = products.first;
          checkCartStatus();
        });
      }
    });
  }

  void checkCartStatus() {
    FirebaseFirestore.instance
        .collection("Cart")
        .where("pid", isEqualTo: product.id)
        .where("Uid", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        isInCart = querySnapshot.docs.isNotEmpty;
        buttonText =
            isInCart ? "Go to Cart" : "Add to Cart"; // Update button text
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getProductDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productname),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("Product")
                    .where("product_name", isEqualTo: widget.productname)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else {
                    final List<Product_Model> products = snapshot.data!.docs
                        .map((doc) => Product_Model.fromFirestore(doc))
                        .toList();
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        var product = products[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CarouselSlider.builder(
                              itemCount: product.images.length,
                              itemBuilder: (context, index, realIndex) {
                                return Image.network(
                                  product.images[index],
                                  fit: BoxFit.cover,
                                );
                              },
                              options: CarouselOptions(
                                autoPlay: true,
                                aspectRatio: 2.0,
                                enlargeCenterPage: true,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                double total = (double.parse(qty) *
                                    double.parse(product.product_newprice));
                                try {
                                  if (product.fav == "no") {
                                    FirebaseFirestore.instance
                                        .collection("Favorites")
                                        .doc(product.id)
                                        .set({
                                      "images": product.images,
                                      "price_new": product.product_newprice,
                                      "price_old": product.product_price,
                                      "product_name": product.product_name,
                                      "qty": qty,
                                      "Uid": FirebaseAuth
                                          .instance.currentUser?.uid
                                          .toString(),
                                      "total": total
                                    }).then((value) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text("Fav Added")));
                                    });
                                    FirebaseFirestore.instance
                                        .collection("Product")
                                        .doc(product.id)
                                        .update({"fav": "yes"});
                                  } else if (product.fav == "yes") {
                                    FirebaseFirestore.instance
                                        .collection("Favorites")
                                        .doc(product.id)
                                        .delete()
                                        .then((value) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text("Fav Removed")));
                                    });
                                    FirebaseFirestore.instance
                                        .collection("Product")
                                        .doc(product.id)
                                        .update({"fav": "no"});
                                  }
                                } catch (e) {
                                  print(e.toString());
                                }
                              },
                              icon: (product.fav == "no")
                                  ? const Icon(Icons.favorite_border)
                                  : const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Product Name: ${product.product_name}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "-${product.discount}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  "₹${product.product_newprice}",
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.green),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  "MRP:",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  product.product_price,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.red,
                                      decorationColor: Colors.red,
                                      decoration: TextDecoration.lineThrough),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "In stock",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  "Quantity",
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                DropdownButton<String>(
                                  value: qty,
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      qty =
                                          newValue; // Ensure newValue is not null
                                      setState(() {});
                                    }
                                  },
                                  items: options.map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  double total = (double.parse(qty) *
                                      double.parse(product.product_newprice));
                                  FirebaseFirestore.instance
                                      .collection("Cart")
                                      .where("pid", isEqualTo: product.id)
                                      .where("Uid",
                                          isEqualTo: FirebaseAuth
                                              .instance.currentUser?.uid)
                                      .get()
                                      .then((QuerySnapshot querySnapshot) {
                                    if (querySnapshot.docs.isNotEmpty) {
                                      // Item is already in the cart
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Cart(),
                                        ),
                                      );
                                    } else {
                                      // Item is not in the cart, add it to the cart
                                      FirebaseFirestore.instance
                                          .collection("Cart")
                                          .doc(product.id)
                                          .set({
                                        "images": product.images,
                                        "price_new": product.product_newprice,
                                        "price_old": product.product_price,
                                        "product_name": product.product_name,
                                        "qty": qty,
                                        "Uid": FirebaseAuth
                                            .instance.currentUser?.uid
                                            .toString(),
                                        "total": total,
                                        "pid": product.id
                                      }).then((value) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Added to the cart Successfully"),
                                          ),
                                        );
                                        setState(() {
                                          buttonText = "Go to Cart";
                                        });
                                      });
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                ),
                                child: Text(
                                  buttonText,
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: // Inside the StreamBuilder's ListView.builder itemBuilder method
                                  ElevatedButton(
                                onPressed: () {
                                  double total = (double.parse(qty) *
                                      double.parse(product.product_newprice));
                                  FirebaseFirestore.instance
                                      .collection("Cart")
                                      .doc(product.id)
                                      .get()
                                      .then((DocumentSnapshot docSnapshot) {
                                    if (docSnapshot.exists) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Cart(), // Replace CartScreen with your actual cart screen
                                        ),
                                      );
                                    } else {
                                      FirebaseFirestore.instance
                                          .collection("Cart")
                                          .doc(product.id)
                                          .set({
                                        "images": product.images,
                                        "price_new": product.product_newprice,
                                        "price_old": product.product_price,
                                        "product_name": product.product_name,
                                        "qty": qty,
                                        "Uid": FirebaseAuth
                                            .instance.currentUser?.uid
                                            .toString(),
                                        "total": total,
                                        "pid": product.id
                                      }).then((value) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Checkout(
                                                productid: product.id,
                                              ),
                                            ));
                                      });
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                ),
                                child: const Text(
                                  "Buy",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Details",
                              style: TextStyle(fontSize: 25),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          product.product_title1,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          product.product_title2,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          product.product_title3,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          product.product_title4,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const Text(
                                          "Color",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          product.product_title1_delail,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          product.product_title2_delail,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          product.product_title3_delail,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          product.product_title4_delail,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          product.product_color,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Text(
                              "About this item",
                              style: TextStyle(fontSize: 25),
                            ),
                            Text(
                              product.product_all,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
