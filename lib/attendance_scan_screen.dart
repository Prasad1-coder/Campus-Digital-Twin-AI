import 'package:flutter/material.dart';

class AttendanceScanScreen extends StatelessWidget {
  const AttendanceScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Attendance"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 120,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              "Scan College QR Code",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Scanner will be added next 🚀"),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Open Scanner"),
            ),
          ],
        ),
      ),
    );
  }
}