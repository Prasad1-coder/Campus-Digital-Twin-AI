import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class EventItem {
  String title;
  String date;
  String time;
  String venue;
  String organizer;
  int totalSeats;
  int registeredCount;
  bool featured;
  bool isCollegeEvent;
  String status; // Draft, Pending HOD, Pending Principal, Registration Open, Live, Completed, Archived
  IconData icon;
  Color color;
  List<String> registeredStudents;

  EventItem({
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.organizer,
    required this.totalSeats,
    this.registeredCount = 0,
    this.featured = false,
    this.isCollegeEvent = false,
    this.status = "Registration Open",
    this.icon = Icons.event_outlined,
    this.color = Colors.blue,
    List<String>? registeredStudents,
  }) : registeredStudents = registeredStudents ?? [];

  int get seatsLeft => totalSeats - registeredCount;
}

class _EventStore {
  // Made list mutable
  static final List<EventItem> events = [
    EventItem(
      title: "TechFest 2026 - Hackathon",
      date: "15 Dec 2024",
      time: "9:00 AM",
      venue: "Main Auditorium",
      organizer: "Computer Dept",
      totalSeats: 100,
      registeredCount: 68,
      featured: true,
      isCollegeEvent: true,
      status: "Registration Open",
      icon: Icons.code_rounded,
      color: Colors.blue,
    ),
    EventItem(
      title: "AI & ML Workshop",
      date: "12 Dec 2024",
      time: "11:00 AM",
      venue: "Seminar Hall 2",
      organizer: "Prof. Sharma",
      totalSeats: 50,
      registeredCount: 45,
      status: "Pending Principal",
      icon: Icons.school_outlined,
      color: Colors.purple,
    ),
    EventItem(
      title: "Cultural Fest - Sangam",
      date: "22 Dec 2024",
      time: "5:00 PM",
      venue: "Open Air Theatre",
      organizer: "Cultural Committee",
      totalSeats: 500,
      registeredCount: 210,
      status: "Pending HOD",
      icon: Icons.celebration_outlined,
      color: Colors.pink,
    ),
  ];
}

class EventsScreen extends StatefulWidget {
  final UserRole userRole;
  final String currentUserName;

  const EventsScreen({
    super.key,
    this.userRole = UserRole.student,
    this.currentUserName = "Prasad",
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final AuthService _authService = AuthService();
  
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _isStudent => widget.userRole == UserRole.student;
  bool get _canApprove => widget.userRole == UserRole.hod || widget.userRole == UserRole.principal;

  // 👇 FIX: Actual Registration Logic
  void _register(EventItem event) {
    setState(() {
      if (!event.registeredStudents.contains(widget.currentUserName)) {
        if (event.seatsLeft > 0) {
          event.registeredCount++;
          event.registeredStudents.add(widget.currentUserName);
          _showSnack("✅ Registered for ${event.title}!", Colors.green);
        } else {
          _showSnack("❌ Seats full", Colors.red);
        }
      } else {
        _showSnack("⚠️ Already registered!", Colors.orange);
      }
    });
  }

  // 👇 FIX: Actual Approval Logic
  void _approveEvent(EventItem event) {
    setState(() {
      if (event.status == "Pending HOD") {
        event.status = event.isCollegeEvent ? "Pending Principal" : "Registration Open";
        _showSnack("Event Approved by HOD!", Colors.green);
      } else if (event.status == "Pending Principal") {
        event.status = "Registration Open";
        _showSnack("Event Published by Principal!", Colors.green);
      }
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _EventStore.events;
    final featured = events.where((e) => e.featured && e.status == "Registration Open").toList();
    final pendingApprovals = events.where((e) => e.status == "Pending HOD" || e.status == "Pending Principal").toList();
    final upcoming = events.where((e) => e.status == "Registration Open" && !e.featured).toList();

    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_primaryDark, _primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        title: const Text("Campus Events", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        children: [
          if (featured.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Text("Featured Event", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 12),
            ...featured.map((e) => _FeaturedCard(
                  event: e,
                  isStudent: _isStudent,
                  onRegister: () => _register(e),
                )),
            const SizedBox(height: 24),
          ],

          if (_canApprove && pendingApprovals.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: Colors.deepOrange, size: 20),
                const SizedBox(width: 6),
                Text("Pending Approvals", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 12),
            ...pendingApprovals.map((e) => _EventCard(
                  event: e,
                  isStudent: _isStudent,
                  onRegister: () => _register(e),
                  onApprove: () => _approveEvent(e),
                )),
            const SizedBox(height: 24),
          ],

          Text("Upcoming Events", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
          const SizedBox(height: 12),

          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text("No upcoming events", style: TextStyle(color: Colors.grey.shade500))),
            )
          else
            ...upcoming.map((e) => _EventCard(
                  event: e,
                  isStudent: _isStudent,
                  onRegister: () => _register(e),
                  onApprove: () => _approveEvent(e),
                )),
        ],
      ),
    );
  }
}

// ============================================================
// FEATURED EVENT CARD
// ============================================================
class _FeaturedCard extends StatelessWidget {
  final EventItem event;
  final bool isStudent;
  final VoidCallback onRegister;

  const _FeaturedCard({required this.event, required this.isStudent, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final full = event.seatsLeft <= 0;
    final isRegistered = event.registeredStudents.contains("Prasad"); // Assuming current user is Prasad for demo

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [event.color, event.color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: event.color.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(event.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.calendar_today_outlined, text: "${event.date} • ${event.time}"),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.location_on_outlined, text: event.venue),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.person_outline, text: event.organizer),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event_seat_outlined, color: Colors.white.withOpacity(0.9), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    full ? "Seats Full" : "${event.seatsLeft} seats left",
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text("Starts in 2 days", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isStudent)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: full ? null : (isRegistered ? null : onRegister), // 👈 Disabled if registered
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: event.color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isRegistered ? "Registered ✅" : (full ? "Seats Full" : "Register Now"), // 👈 Text changes
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// REGULAR EVENT CARD
// ============================================================
class _EventCard extends StatelessWidget {
  final EventItem event;
  final bool isStudent;
  final VoidCallback onRegister;
  final VoidCallback onApprove;

  const _EventCard({required this.event, required this.isStudent, required this.onRegister, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    final full = event.seatsLeft <= 0;
    final isRegistered = event.registeredStudents.contains("Prasad");
    bool isPending = event.status == "Pending HOD" || event.status == "Pending Principal";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isPending ? Colors.orange.shade100 : Colors.grey.shade200, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    Text("${event.date} • ${event.time}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(event.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                )
              else if (!isStudent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text("Open", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(event.venue, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(width: 12),
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(event.organizer, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: full ? Colors.red.shade50 : (isRegistered ? Colors.blue.shade50 : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isRegistered ? "Registered" : (full ? "Full" : "${event.seatsLeft} seats left"),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: full ? Colors.red.shade700 : (isRegistered ? Colors.blue.shade700 : Colors.green.shade700)),
                  ),
                )
              else
                const SizedBox.shrink(),
              
              // 👇 FIX: Action Buttons Logic
              if (isPending)
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text("Approve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else if (isStudent)
                ElevatedButton(
                  onPressed: full ? null : (isRegistered ? null : onRegister),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(isRegistered ? "Registered" : "Register", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          )
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }
}