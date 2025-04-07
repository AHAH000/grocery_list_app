import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

const String UNSPLASH_ACCESS_KEY =
    "wASYLXuTmKgytq8WFKvnTFPxts5X73PUfL5pJ4-AT3o";

class RecipePushScreen extends StatefulWidget {
  final QueryDocumentSnapshot recipe;

  const RecipePushScreen({super.key, required this.recipe});

  @override
  State<RecipePushScreen> createState() => _RecipePushScreenState();
}

class _RecipePushScreenState extends State<RecipePushScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<String> selectedIngredients = [];
  final Map<String, String> _imageCache = {};

  @override
  void initState() {
    super.initState();
    selectedIngredients = List<String>.from(widget.recipe['ingredients']);
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
      print("Error fetching image for $query: $error");
    }
    return 'images/placeholder.png';
  }

  Future<void> _pushIngredientsToList() async {
    final listsSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("grocery_lists")
        .get();

    if (listsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No grocery lists found.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select a List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...listsSnapshot.docs.map((doc) {
              final listId = doc.id;
              final listName = doc['name'];
              return ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: Text(listName),
                onTap: () async {
                  Navigator.pop(context);
                  for (final ingredient in selectedIngredients) {
                    final imageUrl = await _fetchImage(ingredient);

                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user!.uid)
                        .collection("grocery_lists")
                        .doc(listId)
                        .collection("items")
                        .add({
                      "name": ingredient,
                      "quantity": 1,
                      "category": "Other",
                      "image": imageUrl,
                      "purchased": false,
                      "createdAt": FieldValue.serverTimestamp(),
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text("Ingredients added to $listName",
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allIngredients = List<String>.from(widget.recipe['ingredients']);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.recipe['name']),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select ingredients to add:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: allIngredients.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final ingredient = allIngredients[index];
                  final isSelected = selectedIngredients.contains(ingredient);
                  return CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: isSelected
                        ? Colors.deepPurple.withOpacity(0.1)
                        : Colors.white,
                    title: Text(
                      ingredient,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedIngredients.add(ingredient);
                        } else {
                          selectedIngredients.remove(ingredient);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pushIngredientsToList,
              icon: const Icon(Icons.playlist_add_check, color: Colors.white),
              label: const Text("Add to Grocery List",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
