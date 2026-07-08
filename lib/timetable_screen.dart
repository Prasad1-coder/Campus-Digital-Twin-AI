import 'package:flutter/material.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = [
      {"time": "9:00 AM", "subject": "Data Structures"},
      {"time": "10:00 AM", "subject": "Python Programming"},
      {"time": "11:30 AM", "subject": "DBMS"},
      {"time": "2:00 PM", "subject": "Computer Networks"},
      {"time": "3:30 PM", "subject": "Project Lab"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Timetable"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 5,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.schedule),
              ),
              title: Text(subjects[index]["subject"]!),
              subtitle: Text(subjects[index]["time"]!),
            ),
          );
        },
      ),
    );
  }
}