import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notifications_service.dart';

class SetNotificationScreen extends StatefulWidget {
  const SetNotificationScreen({Key? key}) : super(key: key);

  @override
  State<SetNotificationScreen> createState() => _SetNotificationScreenState();
}

class _SetNotificationScreenState extends State<SetNotificationScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String? selectedListId;
  String? selectedListName;
  DateTime? selectedDateTime;

  // Optional flag: create reminders for each grocery list during fetch
  bool createReminders = false;

  Future<List<Map<String, dynamic>>> _fetchUserLists() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("grocery_lists")
        .get();

    final List<Map<String, dynamic>> lists = [];

    for (var doc in snapshot.docs) {
      final listId = doc.id;
      final listName = doc['name'];

      lists.add({"id": listId, "name": listName});

      if (createReminders) {
        final reminderTime = DateTime.now().add(Duration(minutes: 1));
        try {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user!.uid)
              .collection("reminders")
              .add({
            'listId': listId,
            'listName': listName,
            'reminderTime': reminderTime.toIso8601String(),
            'createdAt': Timestamp.now(),
          });
          print("✅ Reminder added for list: $listName");
        } catch (e) {
          print("❌ Error adding reminder: $e");
        }
      }
    }

    return lists;
  }

  void _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _scheduleNotification() async {
    if (selectedListId == null || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a list and time")),
      );
      return;
    }

    final now = DateTime.now();
    print("⏰ Now: $now");
    print("📅 Selected time: $selectedDateTime");

    if (selectedDateTime!.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot schedule a reminder in the past.")),
      );
      return;
    }

    try {
      // 1. Save to Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("reminders")
          .add({
        'listId': selectedListId,
        'listName': selectedListName,
        'reminderTime': selectedDateTime!.toIso8601String(),
        'createdAt': Timestamp.now(),
      });
      print("✅ Reminder saved to Firestore");

      // 2. Schedule local notification
      await scheduleReminderNotification(selectedDateTime!, selectedListName!);
      print("✅ Local notification scheduled");
    } catch (e) {
      print("❌ Error scheduling reminder: $e");
    }

    // 3. Confirm to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reminder set for ${selectedDateTime.toString()}"),
      ),
    );

    // 4. Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return Center(child: Text("Please login first."));

    return Scaffold(
      appBar: AppBar(
        title: Text("Set Grocery Reminder"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserLists(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final lists = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Select a Grocery List",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  value: selectedListId,
                  hint: Text("Choose a list"),
                  items: lists.map((list) {
                    return DropdownMenuItem<String>(
                      value: list["id"],
                      child: Text(list["name"]),
                      onTap: () {
                        selectedListName = list["name"];
                      },
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedListId = value);
                  },
                ),
                const SizedBox(height: 30),
                Text("Choose Reminder Time",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.access_time),
                  label: Text(
                    selectedDateTime == null
                        ? "Pick Time"
                        : "${selectedDateTime!.toLocal()}".split('.')[0],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: _pickDateTime,
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.notifications_active),
                    label: Text("Set Reminder"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: _scheduleNotification,
                  ),
                ),
                const SizedBox(height: 30),
                Divider(),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.bolt),
                    label: Text("🔥 Test Notification in 5s"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                    onPressed: () {
                      final testTime = DateTime.now().add(Duration(seconds: 5));
                      print("🧪 Scheduling test notification for $testTime");
                      scheduleReminderNotification(testTime, "Test List");
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
