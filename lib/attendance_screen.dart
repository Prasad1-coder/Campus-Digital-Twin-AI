import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
   AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.book),
              title: Text("Data Structures"),
              subtitle: Text("Attendance: 92%"),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.code),
              title: Text("Python"),
              subtitle: Text("Attendance: 88%"),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.storage),
              title: Text("DBMS"),
              subtitle: Text("Attendance: 95%"),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.memory),
              title: Text("Computer Networks"),
              subtitle: Text("Attendance: 90%"),
            ),
          ),
        ],
      ),
    );
  }
}