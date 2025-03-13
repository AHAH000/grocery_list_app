import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  @override
  void initState() {
    super.initState();

    // ✅ Listen for Auth changes (Logout detection)
    _auth.authStateChanges().listen((User? currentUser) {
      if (currentUser == null) {
        // ✅ User is signed out, navigate to Login screen
        Navigator.pushReplacementNamed(context, 'LoginScreen');
      } else {
        setState(() {
          user = currentUser;
        });
      }
    });
  }

  void signOut() async {
    await _auth.signOut(); // ✅ This triggers authStateChanges listener
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ HomePage Image (Properly Scaled & Centered)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'images/HomePageImg.png',
                    width: 180, // ✅ Adjusted width
                    height: 180, // ✅ Adjusted height
                    fit: BoxFit.contain, // ✅ Ensures no distortion
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Greeting Section (Better Spacing & Alignment)
              Text(
                'Hello, ${user?.email ?? 'User'} 👋',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'What would you like to do today?',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ✅ Grid Menu for Navigation (Maintains Symmetry)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    icon: Icons.shopping_cart,
                    title: 'View Groceries',
                    onTap: () =>
                        Navigator.pushNamed(context, 'ViewGroceriesScreen'),
                  ),
                  _buildMenuCard(
                    icon: Icons.add_circle,
                    title: 'Add Items',
                    onTap: () => Navigator.pushNamed(context, 'AddItemScreen'),
                  ),
                  _buildMenuCard(
                    icon: Icons.list_alt,
                    title: 'My Lists',
                    onTap: () => Navigator.pushNamed(context, 'MyListsScreen'),
                  ),
                  _buildMenuCard(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () => Navigator.pushNamed(context, 'SettingsScreen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Custom Gradient AppBar
  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      title: const Text(
        'Grocery List 🛒',
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1D2671),
              Color(0xFFC33764)
            ], // ✅ Updated Modern Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 5,
      actions: [
        // Logout Button with Animation
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: signOut,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Interactive Menu Cards with Improved Color Scheme
  Widget _buildMenuCard(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        color: const Color(0xFFF8F9FA), // ✅ Soft background color
        shadowColor: Colors.black26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 50, color: Color(0xFF6A0572)), // ✅ Improved Icon Color
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50)),
            ),
          ],
        ),
      ),
    );
  }
}
