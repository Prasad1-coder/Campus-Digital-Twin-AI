import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 60),
            ),

            const SizedBox(height: 20),

            const Text(
              "Prasad",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              "Computer Engineering",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Email"),
                subtitle: const Text("prasad@college.edu"),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.school),
                title: const Text("College"),
                subtitle: const Text("XYZ Engineering College"),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: const Text("Roll Number"),
                subtitle: const Text("CE-2026-101"),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text("Mobile"),
                subtitle: const Text("+91 9876543210"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}