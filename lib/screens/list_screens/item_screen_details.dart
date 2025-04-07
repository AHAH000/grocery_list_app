import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'add_item_screen.dart';

const String UNSPLASH_ACCESS_KEY =
    "wASYLXuTmKgytq8WFKvnTFPxts5X73PUfL5pJ4-AT3o";

class GroceryListDetailScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const GroceryListDetailScreen(
      {super.key, required this.listId, required this.listName});

  @override
  _GroceryListDetailScreenState createState() =>
      _GroceryListDetailScreenState();
}

class _GroceryListDetailScreenState extends State<GroceryListDetailScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final Map<String, String> _imageCache = {};
  String _sortCategory = 'All';
  Map<String, TextEditingController> _quantityControllers = {};
  Map<String, bool> _isChecked = {}; // Track checkbox animations

  Future<String> _fetchAndSaveItemImage(String itemId, String itemName) async {
    if (_imageCache.containsKey(itemName)) return _imageCache[itemName]!;
    if (itemName.isEmpty) return "images/placeholder.png";

    final url =
        "https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(itemName)}&client_id=$UNSPLASH_ACCESS_KEY&per_page=1";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          String fetchedImageUrl = data['results'][0]['urls']['regular'];

          await FirebaseFirestore.instance
              .collection("users")
              .doc(user!.uid)
              .collection("grocery_lists")
              .doc(widget.listId)
              .collection("items")
              .doc(itemId)
              .update({"image": fetchedImageUrl});

          _imageCache[itemName] = fetchedImageUrl;
          return fetchedImageUrl;
        }
      }
    } catch (e) {
      print("❌ Error fetching image: $e");
    }

    return "images/placeholder.png";
  }

  void _sortItemsByCategory(List<QueryDocumentSnapshot> items) {
    if (_sortCategory != 'All') {
      items.removeWhere((item) => item['category'] != _sortCategory);
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              Text('Sort by Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(),
              Wrap(
                spacing: 8,
                children: [
                  'All',
                  'Dairy',
                  'Fruits',
                  'Vegetables',
                  'Beverages',
                  'Bakery'
                ]
                    .map((category) => ChoiceChip(
                          label: Text(category),
                          selected: _sortCategory == category,
                          onSelected: (selected) {
                            setState(() => _sortCategory = category);
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateQuantity(String itemId, int change) {
    final controller = _quantityControllers[itemId];
    if (controller != null) {
      int newValue = (int.tryParse(controller.text) ?? 0) + change;
      if (newValue < 0) newValue = 0;
      controller.text = newValue.toString();

      FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("grocery_lists")
          .doc(widget.listId)
          .collection("items")
          .doc(itemId)
          .update({'quantity': newValue});
    }
  }

  Future<void> _checkAllPurchased() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("grocery_lists")
        .doc(widget.listId)
        .collection("items")
        .get();

    bool allPurchased = snapshot.docs.isNotEmpty &&
        snapshot.docs.every((doc) => (doc['purchased'] ?? false) == true);

    if (allPurchased) {
      _showCongratulationDialog();
    }
  }

  void _showCongratulationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Congratulations! 🎉"),
          content: Text("You've purchased all the items on your list!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(String itemId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("grocery_lists")
        .doc(widget.listId)
        .collection("items")
        .doc(itemId)
        .delete();
  }

  void _showDeleteConfirmation(String itemId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Item"),
          content: Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteItem(itemId);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("User not found"));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        actions: [
          TextButton.icon(
            onPressed: _showSortOptions,
            icon: Icon(Icons.sort, color: Colors.white),
            label: Text("Sort", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(user!.uid)
              .collection("grocery_lists")
              .doc(widget.listId)
              .collection("items")
              .orderBy("purchased",
                  descending: false) // Sort unchecked items first
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final items = snapshot.data!.docs;
            _sortItemsByCategory(items);

            if (items.isEmpty) {
              return Center(
                child: Text(
                  _sortCategory == 'All'
                      ? "No items found in this list."
                      : "No products found for category: $_sortCategory",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index];
                String itemId = item.id;
                String itemName = item["name"] ?? "Unnamed Item";
                String imageUrl = item["image"] ?? "";
                bool isPurchased = item["purchased"] ?? false;

                if (!_quantityControllers.containsKey(itemId)) {
                  _quantityControllers[itemId] =
                      TextEditingController(text: item['quantity'].toString());
                }

                return Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width *
                          0.9), // Prevents overflow
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  padding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5), // Adjust padding
                  decoration: BoxDecoration(
                    color: isPurchased ? Colors.green.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Item Image
                      CachedNetworkImage(
                        imageUrl: imageUrl.isNotEmpty
                            ? imageUrl
                            : "images/placeholder.png",
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Image.asset(
                          'images/placeholder.png',
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 10), // Space between image and text

                      // Item Name & Quantity Controls
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow
                                  .ellipsis, // Prevents text from overflowing
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove,
                                      color: Colors.red, size: 28),
                                  onPressed: () => _updateQuantity(itemId, -1),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: TextField(
                                    controller: _quantityControllers[itemId],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        border: InputBorder.none),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add, color: Colors.green),
                                  onPressed: () => _updateQuantity(itemId, 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10), // Space before trailing icons

                      // Checkbox and Delete Icon (Properly Aligned)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: isPurchased,
                            onChanged: (_) async {
                              setState(() => _isChecked[itemId] = true);
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user!.uid)
                                  .collection("grocery_lists")
                                  .doc(widget.listId)
                                  .collection("items")
                                  .doc(itemId)
                                  .update({"purchased": !isPurchased});

                              _checkAllPurchased(); // Check if all items are purchased
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(itemId),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddItemScreen(listId: widget.listId)));
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}
