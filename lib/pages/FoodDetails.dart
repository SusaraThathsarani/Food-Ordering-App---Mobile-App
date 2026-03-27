import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodDetails extends StatefulWidget {
  final Map item;

  const FoodDetails({super.key, required this.item});

  @override
  _FoodDetailsState createState() => _FoodDetailsState();
}

class _FoodDetailsState extends State<FoodDetails> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    double price = (widget.item['amount'] as num).toDouble() * quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(widget.item['imageUrl'], height: 200),
            ),
            SizedBox(height: 16),
            Text(widget.item['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(widget.item['description'], style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Quantity:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (quantity > 1) quantity--;
                        });
                      },
                    ),
                    Text(quantity.toString(), style: TextStyle(fontSize: 18)),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text("Total: \$${price.toStringAsFixed(2)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                addToCart(widget.item, quantity);
              },
              child: Text("Add to Cart"),
            ),
          ],
        ),
      ),
    );
  }
String? getUserId() {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid; // Returns null if the user is not logged in
}

  void addToCart(Map item, int quantity) async {
    final String apiUrl = "http://localhost:5000/api/cart/addToCart"; // Replace with your backend URL

    final userId = getUserId();

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Please log in to add items to the cart.'),
    ));
    return;
  }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId, // Replace with the actual user ID
          'foodItemId': item['_id'], 
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('Item added to cart successfully: $responseBody');
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${item['name']} added to cart!'),
        ));
      } else {
        print('Failed to add to cart: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add ${item['name']} to cart.'),
        ));
      }
    } catch (error) {
      print('Error adding to cart: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred. Please try again later.'),
      ));
    }
  }
}
