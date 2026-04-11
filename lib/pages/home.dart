import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../pages/auth_pages/login.dart'; // Import your login page here
import 'FoodDetails.dart';
import 'CartPage.dart'; // Import your Cart page here
import 'package:firebase_auth/firebase_auth.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String selectedCategory = ''; // Track the selected category
  List foodItems = [];
  List displayedItems = [];
  List cartItems = []; // List to track items in the cart
  late String userId;

  @override
  void initState() {
    super.initState();
    fetchFoodItems();
    getUserId();
  }

void getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid; // Store user ID
      });
    }
  }
  Future<void> fetchFoodItems() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/food/getFoodItems'));

      if (response.statusCode == 200) {
        final List fetchedItems = json.decode(response.body);
        setState(() {
          foodItems = fetchedItems;
          if (selectedCategory.isEmpty) {
            displayedItems = fetchedItems;
          if (selectedCategory.isEmpty) {
            displayedItems = fetchedItems;
          } else {
            displayedItems = fetchedItems.where((item) {
              return item['type'].toString().toLowerCase() == selectedCategory.toLowerCase();
            }).toList();
          }
            displayedItems = fetchedItems.where((item) =>
              item['type'].toString().toLowerCase() == selectedCategory.toLowerCase()
            ).toList();
          }
        });
      } else {
        throw Exception('Failed to load food items');
      }
    } catch (error) {
      print('Error fetching food items: $error');
    }
  }

  Future<void> _refreshItems() async {
    await fetchFoodItems();
  }

  void filterItems(String category) {
    setState(() {
      selectedCategory = category; // Update the selected category
      displayedItems = foodItems.where((item) {
        return item['type'].toLowerCase() == category.toLowerCase();
      }).toList();
    });
  }

  void logout() {
    // Clear session data, if any
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void addToCart(Map item) {
    setState(() {
      cartItems.add(item); // Add selected item to the cart
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange,
        title: Text("UrbanFood", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
                tooltip: 'View Cart',
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartItems.length}',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome to UrbanFood! 🍔",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Discover tasty meals",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Categories",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildCategoryButton('rice', "images/pngwing.com (2).png", "Rice"),
                  buildCategoryButton('burger', "images/burger-logo-icon_567288-500-removebg-preview.png", "Burger"),
                  buildCategoryButton('drinks', "images/pngegg (7).png", "Drinks"),
                  buildCategoryButton('pizza', "images/pngwing.com (3).png", "Pizza"),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCategory.isEmpty ? "All Items" : selectedCategory.toUpperCase(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (selectedCategory.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedCategory = '';
                          displayedItems = foodItems;
                        });
                      },
                      child: Text("View All"),
                    ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshItems,
                child: displayedItems.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: 60),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant, size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  "No items found",
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        itemCount: displayedItems.length,
                        itemBuilder: (context, index) {
                          final item = displayedItems[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FoodDetails(item: {
                                    ...item,
                                    'amount': (item['amount'] as num).toDouble(),
                                  }),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              margin: EdgeInsets.only(bottom: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        item['imageUrl'],
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 80,
                                            width: 80,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.error, color: Colors.grey),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 80,
                                            width: 80,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            item['description'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.orange, size: 16),
                                              SizedBox(width: 4),
                                              Text("4.5", style: TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "\$${item['amount']}",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.add, color: Colors.white, size: 20),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => FoodDetails(item: {
                                                    ...item,
                                                    'amount': (item['amount'] as num).toDouble(),
                                                  }),
                                                ),
                                              );
                                            },
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryButton(String category, String imagePath, String label) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () => filterItems(category),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? Colors.orange.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              imagePath,
              height: 40,
              width: 40,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.orange : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
