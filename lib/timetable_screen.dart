import 'package:flutter/material.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {

  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> subjects = [

    {
      "subject":"Data Structures",
      "faculty":"Prof. Sharma",
      "room":"Room 204",
      "time":"09:00 - 10:00",
      "status":"Ongoing",
      "color":Colors.blue,
      "icon":Icons.account_tree,
    },

    {
      "subject":"Python Programming",
      "faculty":"Prof. Patil",
      "room":"Lab 2",
      "time":"10:15 - 11:15",
      "status":"Upcoming",
      "color":Colors.green,
      "icon":Icons.code,
    },

    {
      "subject":"DBMS",
      "faculty":"Prof. Deshmukh",
      "room":"Room 305",
      "time":"11:30 - 12:30",
      "status":"Upcoming",
      "color":Colors.orange,
      "icon":Icons.storage,
    },

    {
      "subject":"Computer Networks",
      "faculty":"Prof. Kulkarni",
      "room":"Room 402",
      "time":"02:00 - 03:00",
      "status":"Upcoming",
      "color":Colors.purple,
      "icon":Icons.wifi,
    },

    {
      "subject":"Project Lab",
      "faculty":"Prof. Joshi",
      "room":"Lab 5",
      "time":"03:15 - 05:00",
      "status":"Upcoming",
      "color":Colors.red,
      "icon":Icons.laptop,
    },
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF4F6FA),

      appBar: AppBar(

        backgroundColor: Colors.blue,

        foregroundColor: Colors.white,

        elevation: 0,

        title: const Text(
          "Smart Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(

        child: Column(

          children: [

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: const BoxDecoration(

                color: Colors.blue,

                borderRadius: BorderRadius.only(

                  bottomLeft: Radius.circular(25),

                  bottomRight: Radius.circular(25),

                ),
              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(

                    "Good Morning 👋",

                    style: TextStyle(

                      color: Colors.white70,

                      fontSize: 16,

                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(

                    "Today's Timetable",

                    style: TextStyle(

                      color: Colors.white,

                      fontSize: 28,

                      fontWeight: FontWeight.bold,

                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(

                    DateTime.now().toString().substring(0,10),

                    style: const TextStyle(

                      color: Colors.white70,

                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(

                    controller: searchController,

                    decoration: InputDecoration(

                      filled: true,

                      fillColor: Colors.white,

                      hintText: "Search Subject",

                      prefixIcon: const Icon(Icons.search),

                      border: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(15),

                        borderSide: BorderSide.none,

                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 15),

              child: Card(

                elevation: 4,

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(18),

                ),

                child: Padding(

                  padding: const EdgeInsets.all(18),

                  child: Column(

                    children: [

                      const Row(

                        children: [

                          Icon(Icons.bar_chart,color: Colors.blue),

                          SizedBox(width:10),

                          Text(

                            "Today's Progress",

                            style: TextStyle(

                              fontSize:18,

                              fontWeight: FontWeight.bold,

                            ),
                          )
                        ],
                      ),

                      const SizedBox(height:18),

                      LinearProgressIndicator(

                        value: .60,

                        minHeight: 10,

                        borderRadius: BorderRadius.circular(20),

                      ),

                      const SizedBox(height:10),

                      const Text(

                        "3 of 5 Classes Completed",

                        style: TextStyle(

                          fontWeight: FontWeight.bold,

                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height:20),
                        Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final item = subjects[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border(
                          left: BorderSide(
                            color: item["color"],
                            width: 6,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [

                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                item["color"].withOpacity(.15),
                            child: Icon(
                              item["icon"],
                              color: item["color"],
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Text(
                                  item["subject"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 16,
                                        color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(item["faculty"]),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16,
                                        color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(item["room"]),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 16,
                                        color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(item["time"]),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Chip(
                            backgroundColor: item["status"] == "Ongoing"
                                ? Colors.green
                                : Colors.orange,
                            label: Text(
                              item["status"],
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: const [
                            Icon(Icons.school,
                                color: Colors.blue,
                                size: 35),
                            SizedBox(height: 8),
                            Text(
                              "5",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text("Classes"),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: const [
                            Icon(Icons.check_circle,
                                color: Colors.green,
                                size: 35),
                            SizedBox(height: 8),
                            Text(
                              "94%",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text("Attendance"),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: const [
                            Icon(Icons.assignment,
                                color: Colors.orange,
                                size: 35),
                            SizedBox(height: 8),
                            Text(
                              "2",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text("Assignments"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 90),

          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Class"),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Feature Coming Soon"),
            ),
          );
        },
      ),
    );
  }
}