import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String UNSPLASH_ACCESS_KEY =
    "wASYLXuTmKgytq8WFKvnTFPxts5X73PUfL5pJ4-AT3o";

class ViewGroceriesScreen extends StatefulWidget {
  const ViewGroceriesScreen({super.key});

  @override
  _ViewGroceriesScreenState createState() => _ViewGroceriesScreenState();
}

class _ViewGroceriesScreenState extends State<ViewGroceriesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _imageCache = {};
  final List<String> categories = [
    "All",
    "Fruits",
    "Vegetables",
    "Dairy",
    "Bakery",
    "Beverages",
    "Meat",
    "Other"
  ];

  List<Map<String, dynamic>> groceries = [];
  List<Map<String, dynamic>> filteredGroceries = [];
  bool isLoading = false;
  String selectedCategory = "All";

  final List<Map<String, String>> groceryItemsWithCategories = [
    {"name": "Apple", "category": "Fruits"},
    {"name": "Banana", "category": "Fruits"},
    {"name": "Orange", "category": "Fruits"},
    {"name": "Strawberry", "category": "Fruits"},
    {"name": "Carrot", "category": "Vegetables"},
    {"name": "Tomato", "category": "Vegetables"},
    {"name": "Potato", "category": "Vegetables"},
    {"name": "Milk", "category": "Dairy"},
    {"name": "Cheese", "category": "Dairy"},
    {"name": "Bread", "category": "Bakery"},
    {"name": "Croissant", "category": "Bakery"},
    {"name": "Orange Juice", "category": "Beverages"},
    {"name": "Cola", "category": "Beverages"},
    {"name": "Chicken", "category": "Meat"},
    {"name": "Beef", "category": "Meat"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialGroceries();
  }

  // Future<void> _fetchInitialGroceries() async {
  //   setState(() => isLoading = true);
  //   List<Map<String, dynamic>> fetchedGroceries = [];

  //   for (var item in groceryItemsWithCategories) {
  //     String imageUrl = await _fetchImage(item['name']!);
  //     fetchedGroceries.add({
  //       "name": item['name'],
  //       "image": imageUrl,
  //       "category": item['category'],
  //       "added": false,
  //       "list": "",
  //       "quantity": 1,
  //     });
  //   }

  //   setState(() {
  //     groceries = fetchedGroceries;
  //     filteredGroceries = groceries;
  //     isLoading = false;
  //   });
  // }
  Future<void> _fetchInitialGroceries() async {
    setState(() => isLoading = true);

    try {
      final fetchedGroceries = await Future.wait(
        groceryItemsWithCategories.map((item) async {
          String imageUrl;
          try {
            imageUrl = await _fetchImage(item['name']!)
                .timeout(const Duration(seconds: 15));
          } catch (e) {
            imageUrl = 'images/placeholder.png';
          }

          return {
            "name": item['name'],
            "image": imageUrl,
            "category": item['category'],
            "added": false,
            "list": "",
            "quantity": 1,
          };
        }),
      );

      setState(() {
        groceries = fetchedGroceries;
        filteredGroceries = groceries;
      });
    } catch (e) {
      print("Failed to fetch groceries: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String> _fetchImage(String query) async {
    if (_imageCache.containsKey(query)) return _imageCache[query]!;

    try {
      final response = await http.get(Uri.parse(
          'https://api.unsplash.com/search/photos?query=$query&client_id=$UNSPLASH_ACCESS_KEY&per_page=1'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          String imageUrl = data['results'][0]['urls']['small'];
          _imageCache[query] = imageUrl;
          return imageUrl;
        }
      }
    } catch (error) {
      print("Error fetching image: $error");
    }
    return 'images/placeholder.png';
  }

  Future<void> _addNewGroceryDialog() async {
    String newName = "";
    String newCategory = "Other";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("➕ Add New Grocery"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (val) => newName = val,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: newCategory,
              items: categories
                  .where((c) => c != "All")
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => newCategory = val!,
              decoration: const InputDecoration(labelText: "Category"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () async {
              if (newName.trim().isEmpty) return;
              Navigator.pop(context);
              await _addNewGrocery(newName.trim(), newCategory);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Grocery added successfully"),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewGrocery(String name, String category) async {
    setState(() => isLoading = true);
    String imageUrl = await _fetchImage(name);
    groceries.add({
      "name": name,
      "image": imageUrl,
      "category": category,
      "added": false,
      "list": "",
      "quantity": 1,
    });
    _applyFilters();
    setState(() => isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      filteredGroceries = groceries.where((item) {
        final nameMatch = item['name']
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
        final catMatch =
            selectedCategory == "All" || item['category'] == selectedCategory;
        return nameMatch && catMatch;
      }).toList();
    });
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          children: categories.map((cat) {
            return ListTile(
              title: Text(cat),
              leading: Icon(Icons.label_important_outlined),
              trailing: selectedCategory == cat
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  selectedCategory = cat;
                  _applyFilters();
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _addItemToUserList(Map<String, dynamic> groceryItem) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in")),
      );
      return;
    }

    final listsSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("grocery_lists")
        .orderBy("createdAt", descending: true)
        .get();

    if (listsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No grocery lists found.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add to which list?"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: listsSnapshot.docs.map((doc) {
              final listName = doc['name'];
              final listId = doc.id;

              return ListTile(
                title: Text(listName),
                leading: const Icon(Icons.shopping_bag_outlined),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.uid)
                      .collection("grocery_lists")
                      .doc(listId)
                      .collection("items")
                      .add({
                    "name": groceryItem['name'],
                    "category": groceryItem['category'],
                    "image": groceryItem['image'],
                    "quantity": groceryItem['quantity'] ?? 1,
                    "purchased": false,
                    "addedAt": FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text("Added to $listName"),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  setState(() {
                    groceryItem['added'] = true;
                  });
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('View Groceries 🛒',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A0572),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: "Sort by Category",
            color: Colors.white,
            onPressed: _showSortDialog,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewGroceryDialog,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Grocery",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 151, 12, 160),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search groceries...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredGroceries.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (_, index) {
                      final item = filteredGroceries[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              offset: const Offset(1, 2),
                              color: Colors.grey.withOpacity(0.2),
                            )
                          ],
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Image.asset('images/placeholder.png'),
                            ),
                          ),
                          title: Text(item['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item['category'],
                              style: const TextStyle(color: Colors.deepPurple)),
                          trailing: IconButton(
                            icon: Icon(
                              item['added']
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: item['added'] ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => _addItemToUserList(item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
