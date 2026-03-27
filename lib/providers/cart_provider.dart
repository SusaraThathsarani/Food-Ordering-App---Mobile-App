import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:food_order_app/models/cart_model.dart';

class CartProvider with ChangeNotifier {
  Cart? _cart;

  Cart? get cart => _cart;

 Future<void> fetchCart(String userId) async {
  try {
    final uri = Uri.parse('http://localhost:5000/api/cart/getCart/$userId');
    print('Fetching cart from: $uri'); // Debug
    
    final response = await http.get(uri);
    print('Response status: ${response.statusCode}'); // Debug
    print('Response body: ${response.body}'); // Debug

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<CartItem> parsedItems = [];
      if (data['items'] is List) {
        for (final item in data['items']) {
          final food = item['foodItemId'];
          // Handle both populated object and plain id string
          final foodId = (food is Map && food['_id'] != null) ? food['_id'] : food?.toString();
          final foodName = (food is Map && food['name'] != null) ? food['name'] : 'Item';
          final imageUrl = (food is Map && food['imageUrl'] != null)
              ? food['imageUrl'].toString()
              : '';
          final priceVal = (food is Map && food['amount'] != null)
              ? (food['amount'] as num).toDouble()
              : 0.0;

          parsedItems.add(
            CartItem(
              id: item['_id']?.toString() ?? '',
              foodItemId: foodId ?? '',
              foodName: foodName,
              imageUrl: imageUrl,
              quantity: (item['quantity'] ?? 0) as int,
              price: priceVal,
            ),
          );
        }
      }

      _cart = Cart(userId: data['userId'] ?? '', items: parsedItems);
      notifyListeners();
    } else if (response.statusCode == 404) {
      // Cart not found - initialize empty cart
      _cart = Cart(userId: userId, items: []);
      notifyListeners();
    } else {
      // Initialize empty cart on any other error
      _cart = Cart(userId: userId, items: []);
      notifyListeners();
    }
  } catch (e) {
    print('Error fetching cart: $e');
    // Initialize empty cart on error
    _cart = Cart(userId: userId, items: []);
    notifyListeners();
  }
}

  Future<void> addToCart(String userId, String foodItemId, int quantity) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/cart/addToCart'),
      body: json.encode({
        'userId': userId,
        'foodItemId': foodItemId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200) {
      fetchCart(userId); // Reload the cart
    } else {
      throw Exception('Failed to add item to cart');
    }
  }

  Future<void> updateCartItem(String userId, String foodItemId, int quantity) async {
    final response = await http.put(
      Uri.parse('http://localhost:5000/api/cart/updateCartItem'),
      body: json.encode({
        'userId': userId,
        'foodItemId': foodItemId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200) {
      fetchCart(userId); // Reload the cart
    } else {
      throw Exception('Failed to update cart item');
    }
  }

  Future<void> removeFromCart(String userId, String foodItemId) async {
    final response = await http.delete(
      Uri.parse('http://localhost:5000/api/cart/removeFromCart'),
      body: json.encode({
        'userId': userId,
        'foodItemId': foodItemId,
      }),
    );

    if (response.statusCode == 200) {
      fetchCart(userId); // Reload the cart
    } else {
      throw Exception('Failed to remove item from cart');
    }
  }
}
