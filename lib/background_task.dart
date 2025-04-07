// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_core/firebase_core.dart'; // ✅ Add this
// import 'package:workmanager/workmanager.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     try {
//       // ✅ Initialize Firebase
//       await Firebase.initializeApp();

//       // ✅ Use passed UID
//       final uid = inputData?['uid'];
//       if (uid == null) {
//         print("❌ UID missing in inputData.");
//         return Future.value(false);
//       }

//       tz.initializeTimeZones();

//       final now = DateTime.now();
//       final nowISO = now.toIso8601String().substring(0, 16);

//       final snapshot = await FirebaseFirestore.instance
//           .collection("users")
//           .doc(uid)
//           .collection("reminders")
//           .get();

//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         final reminderTime = data['reminderTime'];
//         final listName = data['listName'];

//         if (reminderTime != null &&
//             reminderTime.toString().substring(0, 16) == nowISO) {
//           await flutterLocalNotificationsPlugin.show(
//             listName.hashCode,
//             '🛒 Grocery Reminder',
//             'Time to shop for "$listName"',
//             NotificationDetails(
//               android: AndroidNotificationDetails(
//                 'reminder_channel',
//                 'Grocery Reminders',
//                 channelDescription: 'Scheduled grocery list reminders',
//                 importance: Importance.max,
//                 priority: Priority.high,
//               ),
//             ),
//           );
//         }
//       }

//       return Future.value(true);
//     } catch (e) {
//       print("❌ Error in background task: $e");
//       return Future.value(false);
//     }
//   });
// }
