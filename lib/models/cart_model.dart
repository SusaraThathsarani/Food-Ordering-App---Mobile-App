class CartItem {
  final String id;
  final String foodItemId;
  final String foodName;
  final String imageUrl;
  final int quantity;
  final double price;

  CartItem({
    required this.id,
    required this.foodItemId,
    required this.foodName,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });
}

class Cart {
  final String userId;
  List<CartItem> items;

  Cart({required this.userId, required this.items});

  // Calculate total price of all cart items
  double get totalPrice {
    double total = 0;
    for (var item in items) {
      total += item.price * item.quantity;
    }
    return total;
  }
}
