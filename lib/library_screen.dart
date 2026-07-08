import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final books = [
      {
        "title": "Data Structures",
        "author": "Mark Allen Weiss",
        "status": "Available",
        "rack": "A-12"
      },
      {
        "title": "Python Programming",
        "author": "Guido",
        "status": "Issued",
        "rack": "B-08"
      },
      {
        "title": "Operating System",
        "author": "Galvin",
        "status": "Available",
        "rack": "C-15"
      },
      {
        "title": "Database Management",
        "author": "Korth",
        "status": "Available",
        "rack": "D-05"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Library"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Book...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {

                final book = books[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  child: ListTile(
                    leading: const Icon(
                      Icons.menu_book,
                      color: Colors.blue,
                    ),

                    title: Text(book["title"]!),

                    subtitle: Text(
                      "Author : ${book["author"]}\n"
                      "Rack : ${book["rack"]}",
                    ),

                    trailing: Chip(
                      label: Text(book["status"]!),
                      backgroundColor:
                          book["status"] == "Available"
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}