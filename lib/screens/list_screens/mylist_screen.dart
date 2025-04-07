import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_screen_details.dart';
import 'package:share_plus/share_plus.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({super.key});

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? user;
  String userId = "";
  final TextEditingController _listNameController = TextEditingController();
  bool _isAdding = false; // Track list creation status
  bool _isButtonEnabled = false; // Track if the button should be enabled

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      userId = user!.uid;
    }
  }

  // ✅ Check if list name already exists
  Future<bool> _isDuplicateListName(String listName) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("grocery_lists")
        .where("name", isEqualTo: listName.trim())
        .get();

    return query.docs.isNotEmpty; // Returns true if a duplicate exists
  }

  // ✅ Add a new grocery list (Prevents duplicate)
  Future<void> _addGroceryList() async {
    if (_listNameController.text.trim().isEmpty) return;

    setState(() => _isAdding = true);

    bool isDuplicate =
        await _isDuplicateListName(_listNameController.text.trim());
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("List already exists!"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isAdding = false);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("grocery_lists")
          .add({
        "name": _listNameController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      _listNameController.clear();
      setState(() => _isButtonEnabled = false); // Disable button after adding
    } catch (e) {
      print("Error adding grocery list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error adding list. Try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAdding = false);
    }
  }

  // ✅ Edit a grocery list name
  Future<void> _editGroceryList(String listId, String currentName) async {
    TextEditingController editController =
        TextEditingController(text: currentName);
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit List Name"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: "Enter new list name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (isUpdating) return;
              setState(() => isUpdating = true);

              String newName = editController.text.trim();
              if (newName.isEmpty || newName == currentName) return;

              bool isDuplicate = await _isDuplicateListName(newName);
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("List name already exists!"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(userId)
                  .collection("grocery_lists")
                  .doc(listId)
                  .update({"name": newName});

              if (mounted) Navigator.pop(context); // Close dialog
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ✅ Delete grocery list
  Future<void> _deleteGroceryList(String listId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("grocery_lists")
          .doc(listId)
          .delete();
    } catch (e) {
      print("Error deleting grocery list: $e");
    }
  }

  Future<void> _shareGroceryList(String listId, String listName) async {
    try {
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("grocery_lists")
          .doc(listId)
          .collection("items")
          .get();

      if (itemsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("List is empty. Nothing to share.")),
        );
        return;
      }

      final itemLines = itemsSnapshot.docs.map((doc) {
        final name = doc['name'];
        final qty = doc['quantity'] ?? 1;
        final status = doc['purchased'] == true ? "✔" : "❌";
        return "$status $name (x$qty)";
      }).toList();

      final message = "🛒 Grocery List: $listName\n\n" + itemLines.join("\n");

      await Share.share(message, subject: "Shared Grocery List");
    } catch (e) {
      print("❌ Error sharing list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sharing list: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Grocery Lists',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 5,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // ✅ Search Bar + Add List Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _listNameController,
                    onChanged: (text) {
                      setState(() {
                        _isButtonEnabled = text.trim().isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter Grocery List Name',
                      prefixIcon:
                          const Icon(Icons.list, color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ✅ Show loading indicator or Add button dynamically
                _isAdding
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _isButtonEnabled ? _addGroceryList : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isButtonEnabled
                              ? Colors.deepPurple
                              : Colors.grey, // Disable color when empty
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 28),
                      ),
              ],
            ),
          ),

          // ✅ Display Grocery Lists
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(userId)
                  .collection("grocery_lists")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lists = snapshot.data!.docs;

                if (lists.isEmpty) {
                  return const Center(
                      child: Text("No grocery lists found.",
                          style: TextStyle(fontSize: 18, color: Colors.grey)));
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    var listData = lists[index];

                    return GestureDetector(
                      onLongPress: () =>
                          _editGroceryList(listData.id, listData["name"]),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child:
                                Icon(Icons.shopping_cart, color: Colors.white),
                          ),
                          title: Text(
                            listData["name"],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle:
                              const Text("Tap to view, Long Press to Edit"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.share, color: Colors.blue),
                                onPressed: () => _shareGroceryList(
                                    listData.id, listData["name"]),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteGroceryList(listData.id),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroceryListDetailScreen(
                                  listId: listData.id,
                                  listName: listData["name"],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
