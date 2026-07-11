import 'package:flutter/material.dart';
import 'profile_screen.dart'; // UserRole yahan se aata hai

// 👇 Simple in-memory models
class EventItem {
  String title;
  String date;
  String time;
  String venue;
  String organizer;
  int totalSeats;
  int registeredCount;
  bool featured;
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
    this.icon = Icons.event_outlined,
    this.color = Colors.blue,
    List<String>? registeredStudents,
  }) : registeredStudents = registeredStudents ?? [];

  int get seatsLeft => totalSeats - registeredCount;
}

class _EventStore {
  static final List<EventItem> events = [
    EventItem(
      title: "TechFest 2026 - Hackathon",
      date: "15 august 2026",
      time: "9:00 AM",
      venue: "Main Auditorium",
      organizer: "Computer Dept",
      totalSeats: 100,
      registeredCount: 68,
      featured: true,
      icon: Icons.code_rounded,
      color: Colors.blue,
    ),
    EventItem(
      title: "Cultural Fest - Sangam",
      date: "22 July 2026",
      time: "5:00 PM",
      venue: "Open Air Theatre",
      organizer: "Cultural Committee",
      totalSeats: 300,
      registeredCount: 210,
      icon: Icons.celebration_outlined,
      color: Colors.purple,
    ),
    EventItem(
      title: "Chemistry Workshop",
      date: "18 July 2026",
      time: "11:00 AM",
      venue: "Chem Lab - B",
      organizer: "Chemistry Dept",
      totalSeats: 40,
      registeredCount: 40,
      icon: Icons.science_outlined,
      color: Colors.green,
    ),
    EventItem(
      title: "Sports Meet - Annual",
      date: "28 July 2026",
      time: "8:00 AM",
      venue: "Sports Ground",
      organizer: "Sports Dept",
      totalSeats: 200,
      registeredCount: 95,
      icon: Icons.sports_soccer_outlined,
      color: Colors.orange,
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
  bool get isAdmin => widget.userRole == UserRole.teacher;

  void _register(EventItem event) {
    if (event.registeredStudents.contains(widget.currentUserName)) {
      _showSnack("⚠️ Already registered!", Colors.orange);
      return;
    }
    if (event.seatsLeft <= 0) {
      _showSnack("❌ Seats full", Colors.red);
      return;
    }
    setState(() {
      event.registeredCount++;
      event.registeredStudents.add(widget.currentUserName);
    });
    _showSnack("✅ Registered for ${event.title}!", Colors.green);
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

  void _deleteEvent(EventItem event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Event?"),
        content: Text("${event.title} ko delete karna hai?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => _EventStore.events.remove(event));
              Navigator.pop(context);
              _showSnack("Event delete ho gaya", Colors.red);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openCreateOrEdit({EventItem? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateEditEventScreen(
          existing: existing,
          onSave: (event) {
            setState(() {
              if (existing == null) {
                _EventStore.events.add(event);
              }
            });
          },
        ),
      ),
    );
  }

  void _openRegistrations(EventItem event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _RegistrationsScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _EventStore.events;
    final featured = events.where((e) => e.featured).toList();
    final regular = events.where((e) => !e.featured).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Campus Events", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text("Create Event", style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () => _openCreateOrEdit(),
            )
          : null,
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
                  isAdmin: isAdmin,
                  onRegister: () => _register(e),
                  onEdit: () => _openCreateOrEdit(existing: e),
                  onDelete: () => _deleteEvent(e),
                  onViewRegs: () => _openRegistrations(e),
                )),
            const SizedBox(height: 24),
          ],

          Text("Upcoming Events", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
          const SizedBox(height: 12),

          if (regular.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text("Koi upcoming event nahi", style: TextStyle(color: Colors.grey.shade500))),
            )
          else
            ...regular.map((e) => _EventCard(
                  event: e,
                  isAdmin: isAdmin,
                  onRegister: () => _register(e),
                  onEdit: () => _openCreateOrEdit(existing: e),
                  onDelete: () => _deleteEvent(e),
                  onViewRegs: () => _openRegistrations(e),
                )),
        ],
      ),
    );
  }
}

// ============================================================
// FEATURED EVENT CARD (big banner style)
// ============================================================
class _FeaturedCard extends StatelessWidget {
  final EventItem event;
  final bool isAdmin;
  final VoidCallback onRegister;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewRegs;

  const _FeaturedCard({
    required this.event,
    required this.isAdmin,
    required this.onRegister,
    required this.onEdit,
    required this.onDelete,
    required this.onViewRegs,
  });

  @override
  Widget build(BuildContext context) {
    final full = event.seatsLeft <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [event.color, event.color.withOpacity(0.7)],
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
                child: Icon(event.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.calendar_today_outlined, text: "${event.date} • ${event.time}"),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.location_on_outlined, text: event.venue),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.person_outline, text: event.organizer),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.event_seat_outlined, color: Colors.white.withOpacity(0.9), size: 15),
              const SizedBox(width: 6),
              Text(
                full ? "Seats Full" : "${event.seatsLeft} seats left",
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (isAdmin) _AdminActions(onEdit: onEdit, onDelete: onDelete, onViewRegs: onViewRegs, light: true),
            ],
          ),
          if (!isAdmin) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: full ? null : onRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: event.color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(full ? "Seats Full" : "Register Now", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
  final bool isAdmin;
  final VoidCallback onRegister;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewRegs;

  const _EventCard({
    required this.event,
    required this.isAdmin,
    required this.onRegister,
    required this.onEdit,
    required this.onDelete,
    required this.onViewRegs,
  });

  @override
  Widget build(BuildContext context) {
    final full = event.seatsLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: event.color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(event.icon, color: event.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text("${event.date} • ${event.time}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(event.venue, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: full ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  full ? "Full" : "${event.seatsLeft} seats left",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: full ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
              const Spacer(),
              if (isAdmin)
                _AdminActions(onEdit: onEdit, onDelete: onDelete, onViewRegs: onViewRegs, light: false)
              else
                ElevatedButton(
                  onPressed: full ? null : onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(full ? "Full" : "Register", style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewRegs;
  final bool light;

  const _AdminActions({required this.onEdit, required this.onDelete, required this.onViewRegs, required this.light});

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : Colors.grey.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(Icons.people_outline, color: color, size: 20), onPressed: onViewRegs, tooltip: "Registrations"),
        IconButton(icon: Icon(Icons.edit_outlined, color: color, size: 20), onPressed: onEdit, tooltip: "Edit"),
        IconButton(icon: Icon(Icons.delete_outline, color: light ? Colors.white : Colors.red, size: 20), onPressed: onDelete, tooltip: "Delete"),
      ],
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
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 15),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

// ============================================================
// CREATE / EDIT EVENT SCREEN (Admin)
// ============================================================
class _CreateEditEventScreen extends StatefulWidget {
  final EventItem? existing;
  final Function(EventItem) onSave;

  const _CreateEditEventScreen({this.existing, required this.onSave});

  @override
  State<_CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<_CreateEditEventScreen> {
  late TextEditingController titleController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController venueController;
  late TextEditingController organizerController;
  late TextEditingController seatsController;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    titleController = TextEditingController(text: e?.title ?? "");
    dateController = TextEditingController(text: e?.date ?? "");
    timeController = TextEditingController(text: e?.time ?? "");
    venueController = TextEditingController(text: e?.venue ?? "");
    organizerController = TextEditingController(text: e?.organizer ?? "");
    seatsController = TextEditingController(text: e?.totalSeats.toString() ?? "");
  }

  void _save() {
    if (titleController.text.trim().isEmpty || dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title aur Date bharo")),
      );
      return;
    }

    if (widget.existing != null) {
      widget.existing!
        ..title = titleController.text
        ..date = dateController.text
        ..time = timeController.text
        ..venue = venueController.text
        ..organizer = organizerController.text
        ..totalSeats = int.tryParse(seatsController.text) ?? widget.existing!.totalSeats;
    } else {
      widget.onSave(EventItem(
        title: titleController.text,
        date: dateController.text,
        time: timeController.text,
        venue: venueController.text,
        organizer: organizerController.text,
        totalSeats: int.tryParse(seatsController.text) ?? 50,
      ));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isEdit ? "Edit Event" : "Create Event"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 👇 Poster upload placeholder
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text("Upload Poster (Coming Soon)", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _field("Event Title", titleController, Icons.title_outlined),
          _field("Date (e.g. 25 July 2026)", dateController, Icons.calendar_today_outlined),
          _field("Time (e.g. 10:00 AM)", timeController, Icons.access_time_outlined),
          _field("Venue", venueController, Icons.location_on_outlined),
          _field("Organizer", organizerController, Icons.person_outline),
          _field("Total Seats", seatsController, Icons.event_seat_outlined, isNumber: true),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEdit ? "Update Event" : "Create Event"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

// ============================================================
// VIEW REGISTRATIONS SCREEN (Admin)
// ============================================================
class _RegistrationsScreen extends StatefulWidget {
  final EventItem event;
  const _RegistrationsScreen({required this.event});

  @override
  State<_RegistrationsScreen> createState() => _RegistrationsScreenState();
}

class _RegistrationsScreenState extends State<_RegistrationsScreen> {
  final Set<String> approved = {};

  @override
  Widget build(BuildContext context) {
    final students = widget.event.registeredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("${widget.event.title} - Registrations"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: "Send Reminder",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("📧 Reminder sent to ${students.length} students"),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
      body: students.isEmpty
          ? Center(child: Text("Abhi koi registration nahi", style: TextStyle(color: Colors.grey.shade500)))
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final name = students[index];
                final isApproved = approved.contains(name);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      isApproved
                          ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
                          : TextButton(
                              onPressed: () => setState(() => approved.add(name)),
                              child: const Text("Approve"),
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
