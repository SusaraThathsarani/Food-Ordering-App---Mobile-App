import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _foodType = 'rice'; // Default value
  final List<String> _categories = ['rice', 'burger', 'dessert', 'beverages'];
  XFile? _image;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  List<dynamic> _foodItems = [];
  String? _editingItemId;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
  }

  // Fetch all food items
  Future<void> _fetchFoodItems() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/food/getFoodItems'));
      if (response.statusCode == 200) {
        setState(() {
          _foodItems = json.decode(response.body);
          for (final item in _foodItems) {
            final t = item['type'];
            if (t is String && t.isNotEmpty && !_categories.contains(t)) {
              _categories.add(t);
            }
          }
          if (!_categories.contains(_foodType)) {
            _foodType = _categories.first;
          }
        });
      }
    } catch (e) {
      print('Error fetching food items: $e');
    }
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No image selected')));
        return;
      }

      final bytes = await image.readAsBytes();

      setState(() {
        _image = image;
        _imageBytes = bytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  // Function to save the food item
  Future<void> _saveFoodItem() async {
    if (_editingItemId == null && (_image == null || _imageBytes == null)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select an image')));
      return;
    }

    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var uri = _editingItemId == null 
          ? Uri.parse('http://localhost:5000/api/food/addFoodItem')
          : Uri.parse('http://localhost:5000/api/food/updateFoodItem/$_editingItemId');
          
      var request = http.MultipartRequest(_editingItemId == null ? 'POST' : 'PUT', uri)
        ..fields['name'] = _nameController.text
        ..fields['type'] = _foodType
        ..fields['description'] = _descriptionController.text
        ..fields['amount'] = _amountController.text;

      // Add image if selected
      if (_image != null && _imageBytes != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            _imageBytes!,
            filename: _image!.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
        }
      }

      var response = await request.send();

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingItemId == null ? 'Food item added successfully!' : 'Food item updated successfully!'))
        );
        _clearForm();
        _fetchFoodItems();
      } else {
        var responseBody = await response.stream.bytesToString();
        print('Failed to save food item: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save food item')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // Edit food item
  void _editFoodItem(dynamic item) {
    setState(() {
      _editingItemId = item['_id'];
      _nameController.text = item['name'];
      _descriptionController.text = item['description'];
      _amountController.text = item['amount'].toString();
      _foodType = item['type'];
      _ensureCategoryInList(_foodType);
      _currentImageUrl = item['imageUrl'];
    });
  }

  // Delete food item
  Future<void> _deleteFoodItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete this food item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/food/deleteFoodItem/$id'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Food item deleted successfully!'))
        );
        _fetchFoodItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete food item'))
        );
      }
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }

  // Clear form
  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _amountController.clear();
    setState(() {
      _image = null;
      _imageBytes = null;
      _editingItemId = null;
      _currentImageUrl = null;
      _ensureCategoryInList('rice');
      _foodType = _categories.contains('rice') ? 'rice' : _categories.first;
    });
  }

  // Ensure dropdown has the current item's category
  void _ensureCategoryInList(String value) {
    if (value.isEmpty) return;
    if (!_categories.contains(value)) {
      _categories.add(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingItemId == null ? 'Add New Food Item' : 'Edit Food Item',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        if (_editingItemId != null)
                          TextButton(
                            onPressed: _clearForm,
                            child: Text('Cancel'),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Food Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price',
                               prefixText: '\$',
                              border:
                                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _foodType,
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _foodType = newValue!;
                                  });
                                },
                                  items: _categories
                                      .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.toUpperCase()),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        _buildImagePreview(),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _pickImage,
                          icon: Icon(Icons.image, color: Colors.white),
                          label: Text('Pick Image', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _saveFoodItem,
                              child: Text(
                                  _editingItemId == null ? 'Save Food Item' : 'Update Food Item',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // List of existing food items
            Text('Manage Food Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _foodItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('No food items found', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _foodItems.length,
                    itemBuilder: (context, index) {
                      final item = _foodItems[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['imageUrl'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          title: Text(item['name'],
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['description'],
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 4),
                              Text('\$${item['amount']} • ${item['type'].toUpperCase()}',
                                  style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editFoodItem(item),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteFoodItem(item['_id']),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image_outlined, color: Colors.orange),
    );
  }

  Widget _buildImagePreview() {
    // Show current image URL if editing and no new image selected
    if (_editingItemId != null && _imageBytes == null && _currentImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _currentImageUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _imagePlaceholder();
          },
        ),
      );
    }
    
    if (_imageBytes == null) {
      return _imagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        _imageBytes!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }
}
