import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:workmanager/workmanager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String userName = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _auth.authStateChanges().listen((User? currentUser) {
      if (currentUser == null) {
        Navigator.pushReplacementNamed(context, 'LoginScreen');
      } else {
        setState(() {
          user = currentUser;
        });

        fetchUserName(user!.uid);
        // _registerReminderTask(user!.uid); // ✅ Register task after login
      }
    });
  }

  Future<void> fetchUserName(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc["name"] ?? "User";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // ✅ Register periodic background task
  // Future<void> _registerReminderTask(String uid) async {
  //   await Workmanager().cancelByUniqueName("grocery_reminder_check");
  //   await Workmanager().registerPeriodicTask(
  //     "grocery_reminder_check",
  //     "groceryReminderCheck",
  //     frequency: const Duration(minutes: 15),
  //     inputData: {
  //       'uid': uid,
  //     },
  //   );
  //   print("🛠️ Background task registered with UID: $uid");
  // }

  void signOut() async {
    await _auth.signOut();
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
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'images/HomePageImg.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      'Hello, $userName 👋',
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
                    icon: Icons.notification_add,
                    title: 'Set Reminder',
                    onTap: () =>
                        Navigator.pushNamed(context, 'SetNotificationScreen'),
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
                  _buildMenuCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Recipes',
                    onTap: () =>
                        Navigator.pushNamed(context, 'AddRecipeScreen'),
                  ),
                  _buildMenuCard(
                    icon: Icons.bookmark_add_rounded,
                    title: 'Saved Recipes',
                    onTap: () =>
                        Navigator.pushNamed(context, 'SavedRecipesScreen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            colors: [Color(0xFF1D2671), Color(0xFFC33764)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 5,
      actions: [
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

  Widget _buildMenuCard(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        color: const Color(0xFFF8F9FA),
        shadowColor: Colors.black26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Color(0xFF6A0572)),
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
