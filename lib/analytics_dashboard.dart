import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("AI Analytics Dashboard"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Campus Overview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "Real-time AI analytics of your campus",
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: const [

                AnalyticsCard(
                  title: "Students",
                  value: "1,250",
                  icon: Icons.school,
                  color: Colors.blue,
                ),

                AnalyticsCard(
                  title: "Teachers",
                  value: "78",
                  icon: Icons.person,
                  color: Colors.green,
                ),

                AnalyticsCard(
                  title: "Attendance",
                  value: "92%",
                  icon: Icons.fact_check,
                  color: Colors.orange,
                ),

                AnalyticsCard(
                  title: "Books",
                  value: "426",
                  icon: Icons.menu_book,
                  color: Colors.purple,
                ),

                AnalyticsCard(
                  title: "Events",
                  value: "12",
                  icon: Icons.event,
                  color: Colors.red,
                ),

                AnalyticsCard(
                  title: "AI Chats",
                  value: "874",
                  icon: Icons.smart_toy,
                  color: Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              "Today's Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SummaryTile(
                      icon: Icons.check_circle,
                      text: "92% students attended today",
                    ),

                    Divider(),

                    SummaryTile(
                      icon: Icons.menu_book,
                      text: "126 books issued today",
                    ),

                    Divider(),

                    SummaryTile(
                      icon: Icons.campaign,
                      text: "3 new notices published",
                    ),

                    Divider(),

                    SummaryTile(
                      icon: Icons.event,
                      text: "2 events scheduled",
                    ),

                    Divider(),

                    SummaryTile(
                      icon: Icons.smart_toy,
                      text: "874 AI questions answered",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const SummaryTile({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Icon(
          icon,
          color: Colors.blue,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}