import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grocery_list/auth.dart';
import 'package:grocery_list/screens/ViewGroceriesScreen.dart';
import 'package:grocery_list/screens/home_screen.dart';
import 'package:grocery_list/screens/login_screen.dart';
import 'package:grocery_list/screens/signup_screen.dart';
import 'package:grocery_list/screens/settings_screen.dart';
import 'package:grocery_list/screens/list_screens/mylist_screen.dart';
import 'package:grocery_list/screens/set_notification_screen.dart';
// import 'package:grocery_list/notifications_service.dart' as notify;
// import 'package:workmanager/workmanager.dart';
// import 'package:grocery_list/background_task.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:grocery_list/screens/recipe_screens/add_recipe_screen.dart';
import 'package:grocery_list/screens/recipe_screens/saved_recipes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();

  // ✅ Initialize local notifications
  // const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  // final initSettings = InitializationSettings(android: androidSettings);
  // await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ✅ Initialize background task dispatcher and register task with UID
  // await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routes: {
          '/': (context) => const Auth(),
          'homeScreen': (context) => const HomeScreen(),
          'SignUpScreen': (context) => const SignUpScreen(),
          'LoginScreen': (context) => LoginScreen(),
          'ViewGroceriesScreen': (context) => const ViewGroceriesScreen(),
          'SettingsScreen': (context) => const SettingsScreen(),
          'MyListsScreen': (context) => const MyListsScreen(),
          'SetNotificationScreen': (context) => const SetNotificationScreen(),
          'AddRecipeScreen': (context) => const AddRecipeScreen(),
          'SavedRecipesScreen': (context) => const SavedRecipesScreen(),
        });
  }
}
