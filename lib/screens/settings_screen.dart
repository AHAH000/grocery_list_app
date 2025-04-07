import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  User? user;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // ✅ Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['name'] ?? "";
          _emailController.text = data['email'] ?? user!.email!;
          _profileImageUrl = data['profilePicture'] ?? "";
        });
      } else {
        print("User document does not exist or is empty");
      }
    } else {
      print("User is not logged in!");
    }

    setState(() => _isLoading = false);
  }

  // ✅ Update user data in Firestore & Authentication
  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (user == null) return;

      if (_emailController.text.trim() != user!.email) {
        await user!.updateEmail(_emailController.text.trim());
      }

      if (_passwordController.text.isNotEmpty) {
        await user!.updatePassword(_passwordController.text.trim());
      }

      await _firestore.collection("users").doc(user!.uid).set({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "profileImageUrl": _profileImageUrl ?? "",
      }, SetOptions(merge: true));

      _showMessage("Profile updated successfully!");
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Upload Profile Picture to Firebase Storage
  Future<void> _uploadProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    setState(() => _isLoading = true);
    File file = File(image.path);
    try {
      Reference ref = _storage.ref().child("profile_pictures/${user!.uid}.jpg");
      await ref.putFile(file);
      String imageUrl = await ref.getDownloadURL();

      setState(() {
        _profileImageUrl = imageUrl;
      });

      await _firestore.collection("users").doc(user!.uid).set({
        "profileImageUrl": imageUrl,
      }, SetOptions(merge: true));
    } catch (e) {
      _showMessage("Failed to upload profile picture.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Logout Function
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, 'LoginScreen');
  }

  // ✅ Show a Message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings ⚙️", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // ✅ Profile Picture Upload
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : const AssetImage("images/default_avatar.png")
                                  as ImageProvider,
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _uploadProfilePicture,
                          tooltip: "Change Profile Picture",
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ✅ Name Input
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Name cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // ✅ Email Input
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // ✅ Password Input (Optional)
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: "New Password (optional)"),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return "Password must be at least 6 characters!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ✅ Save Changes Button
                    ElevatedButton(
                      onPressed: _updateUserData,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple),
                      child: const Text("Save Changes",
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 15),

                    // ✅ Logout Button
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text("Logout",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
