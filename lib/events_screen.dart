import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'permission_model.dart';

class EventItem {
  String id;
  String title;
  String date;
  String time;
  String venue;
  String organizer;
  String category;
  int totalSeats;
  int registeredCount;
  bool featured;
  bool isCollegeEvent;
  String status; // Draft, Pending HOD, Pending Principal, Registration Open, Live, Completed
  IconData icon;
  Color color;
  List<String> registeredStudents;

  EventItem({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.organizer,
    required this.category,
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
  static final List<EventItem> events = [
    EventItem(
      id: "E001",
      title: "TechFest 2026 - Hackathon",
      date: "15 Dec 2024",
      time: "9:00 AM",
      venue: "Main Auditorium",
      organizer: "Computer Dept",
      category: "Hackathon",
      totalSeats: 100,
      registeredCount: 68,
      featured: true,
      isCollegeEvent: true,
      status: "Registration Open",
      icon: Icons.code_rounded,
      color: const Color(0xFF1565C0),
    ),
    EventItem(
      id: "E002",
      title: "AI & ML Workshop",
      date: "12 Dec 2024",
      time: "11:00 AM",
      venue: "Seminar Hall 2",
      organizer: "Prof. Sharma",
      category: "Workshop",
      totalSeats: 50,
      registeredCount: 45,
      status: "Registration Open",
      icon: Icons.school_outlined,
      color: Colors.purple,
    ),
    EventItem(
      id: "E003",
      title: "Inter-Dept Football Finals",
      date: "10 Dec 2024",
      time: "4:00 PM",
      venue: "Sports Ground",
      organizer: "Sports Committee",
      category: "Sports",
      totalSeats: 200,
      registeredCount: 150,
      status: "Live",
      icon: Icons.sports_soccer_outlined,
      color: Colors.green,
    ),
    EventItem(
      id: "E004",
      title: "Guest Lecture: Quantum Computing",
      date: "18 Dec 2024",
      time: "10:00 AM",
      venue: "Main Auditorium",
      organizer: "Principal Office",
      category: "Guest Lecture",
      totalSeats: 300,
      registeredCount: 120,
      isCollegeEvent: true,
      status: "Pending Principal",
      icon: Icons.mic_none_outlined,
      color: Colors.orange,
    ),
    EventItem(
      id: "E005",
      title: "Cultural Fest - Sangam",
      date: "22 Dec 2024",
      time: "5:00 PM",
      venue: "Open Air Theatre",
      organizer: "Cultural Committee",
      category: "Cultural",
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
  
  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _canCreate => _authService.hasPermission('events', 'canCreate');
  bool get _canApprove => _authService.hasPermission('events', 'canApprove');
  bool get _canManage => _authService.hasPermission('events', 'canManage');

  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    "All", "Academic", "Workshop", "Seminar", "Placement Drive", 
    "Hackathon", "Sports", "Cultural", "Technical", "Competition", 
    "Guest Lecture", "Festival", "Community Service"
  ];

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

  void _cancelRegistration(EventItem event) {
    setState(() {
      event.registeredCount--;
      event.registeredStudents.remove(widget.currentUserName);
    });
    _showSnack("Registration cancelled.", Colors.grey);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Event?", style: TextStyle(fontWeight: FontWeight.w800, color: _textDark)),
        content: Text("Are you sure you want to delete '${event.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              setState(() => _EventStore.events.remove(event));
              Navigator.pop(context);
              _showSnack("Event deleted successfully", Colors.red);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
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
          canManage: _canManage,
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

  void _showPassDialog(EventItem event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Event Pass", style: TextStyle(fontWeight: FontWeight.w800, color: _textDark), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Show this at the entry", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _primary, width: 2)),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 120, color: _primary),
                  const SizedBox(height: 12),
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark), textAlign: TextAlign.center),
                  Text("${event.date} • ${event.time}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(event.venue, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _EventStore.events;
    
    // Filter by Category
    List<EventItem> filteredEvents = _selectedCategoryIndex == 0 
        ? events 
        : events.where((e) => e.category == _categories[_selectedCategoryIndex]).toList();

    List<EventItem> featured = filteredEvents.where((e) => e.featured && e.status == "Registration Open").toList();
    List<EventItem> pendingApprovals = filteredEvents.where((e) => e.status == "Pending HOD" || e.status == "Pending Principal").toList();
    List<EventItem> myRegistered = filteredEvents.where((e) => e.registeredStudents.contains(widget.currentUserName)).toList();
    List<EventItem> upcoming = filteredEvents.where((e) => e.status == "Registration Open" && !e.featured).toList();
    List<EventItem> liveEvents = filteredEvents.where((e) => e.status == "Live").toList();

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
        title: const Text("Campus Events", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month_outlined, color: Colors.white), onPressed: () {
            _showSnack("Calendar View (UI Ready)", _primary);
          }),
          if (_canManage)
            IconButton(icon: const Icon(Icons.analytics_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text("Create Event", style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _openCreateOrEdit(),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildCategoryChips(),
            const SizedBox(height: 24),

            if (liveEvents.isNotEmpty) ...[
              _buildSectionHeader("Live Now", Icons.play_circle_fill_rounded, Colors.red),
              const SizedBox(height: 12),
              ...liveEvents.map((e) => _buildEventCard(e, isLive: true)),
              const SizedBox(height: 24),
            ],

            if (featured.isNotEmpty) ...[
              _buildSectionHeader("Featured Event", Icons.star_rounded, Colors.orange),
              const SizedBox(height: 12),
              ...featured.map((e) => _buildFeaturedCard(e)),
              const SizedBox(height: 24),
            ],

            if (pendingApprovals.isNotEmpty && (_canApprove || _canManage)) ...[
              _buildSectionHeader("Pending Approvals", Icons.pending_actions_rounded, Colors.deepOrange),
              const SizedBox(height: 12),
              ...pendingApprovals.map((e) => _buildEventCard(e)),
              const SizedBox(height: 24),
            ],

            if (myRegistered.isNotEmpty) ...[
              _buildSectionHeader("My Registered Events", Icons.check_circle_outline_rounded, Colors.green),
              const SizedBox(height: 12),
              ...myRegistered.map((e) => _buildEventCard(e)),
              const SizedBox(height: 24),
            ],

            _buildSectionHeader("Upcoming Events", Icons.event_outlined, _primary),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text("No upcoming events in this category", style: TextStyle(color: Colors.grey.shade500)),
              ))
            else
              ...upcoming.map((e) => _buildEventCard(e)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  WIDGETS
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search events...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.grey),
            onPressed: () {},
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [_primaryDark, _primary]) : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
      ],
    );
  }

  Widget _buildFeaturedCard(EventItem event) {
    final full = event.seatsLeft <= 0;
    final isRegistered = event.registeredStudents.contains(widget.currentUserName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [event.color, event.color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
                child: Text(event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
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
                child: Text(
                  "Starts in 2 days", // Dummy Countdown
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_canCreate && !_canApprove && !_canManage) // Student View
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: full ? null : (isRegistered ? () => _cancelRegistration(event) : () => _register(event)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: event.color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isRegistered ? "Cancel Registration" : (full ? "Seats Full" : "Register Now"),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          if (isRegistered) // If student is registered, show pass button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showPassDialog(event),
                icon: const Icon(Icons.qr_code, color: Colors.white),
                label: const Text("View Pass", style: TextStyle(color: Colors.white)),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildEventCard(EventItem event, {bool isLive = false}) {
    final full = event.seatsLeft <= 0;
    final isRegistered = event.registeredStudents.contains(widget.currentUserName);
    bool isPending = event.status == "Pending HOD" || event.status == "Pending Principal";

    Color statusColor = Colors.green;
    if (event.status == "Pending HOD") statusColor = Colors.orange;
    if (event.status == "Pending Principal") statusColor = Colors.deepOrange;
    if (event.status == "Draft") statusColor = Colors.grey;
    if (event.status == "Live") statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLive ? Colors.red.shade100 : Colors.grey.shade100, width: isLive ? 1.5 : 1),
        boxShadow: [
          if (isLive) 
            BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))
          else 
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: event.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(event.icon, color: event.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
                          const SizedBox(height: 4),
                          Text("${event.date} • ${event.time}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending || isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    event.status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(child: Text(event.venue, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(event.organizer, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (event.status != "Draft" && event.status != "Pending HOD" && event.status != "Pending Principal")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: full ? Colors.red.shade50 : (isRegistered ? Colors.blue.shade50 : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isRegistered ? "Registered" : (full ? "Full" : "${event.seatsLeft} seats left"),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: full ? Colors.red.shade700 : (isRegistered ? _primary : Colors.green.shade700),
                    ),
                  ),
                )
              else 
                const SizedBox.shrink(),
              
              // Role Based Actions
              if (_canManage || _canApprove || _canCreate) ...[
                if (isPending && _canApprove && event.status == "Pending HOD")
                  _actionButton("Approve", Colors.green, () {
                    setState(() {
                      event.status = event.isCollegeEvent ? "Pending Principal" : "Registration Open";
                    });
                    _showSnack("Event Approved!", Colors.green);
                  }),
                if (isPending && _canManage && event.status == "Pending Principal")
                  _actionButton("Publish", _primary, () {
                    setState(() {
                      event.status = "Registration Open";
                    });
                    _showSnack("Event Published!", _primary);
                  }),
                if (_canCreate || _canManage)
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Event')),
                      const PopupMenuItem(value: 'view', child: Text('View Registrations')),
                      if (_canManage)
                        const PopupMenuItem(value: 'delete', child: Text('Delete Event', style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (val) {
                      if (val == 'edit') _openCreateOrEdit(existing: event);
                      if (val == 'view') _openRegistrations(event);
                      if (val == 'delete') _deleteEvent(event);
                    },
                  ),
              ] else if (event.status == "Registration Open" || event.status == "Live") ...[
                if (isRegistered)
                  TextButton.icon(
                    onPressed: () => _showPassDialog(event), 
                    icon: const Icon(Icons.qr_code, size: 18, color: _primary),
                    label: const Text("Pass", style: TextStyle(color: _primary, fontWeight: FontWeight.w700)),
                  )
                else
                  ElevatedButton(
                    onPressed: full ? null : () => _register(event),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(full ? "Full" : "Register", style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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

// ============================================================
// CREATE / EDIT EVENT SCREEN (Admin)
// ============================================================
class _CreateEditEventScreen extends StatefulWidget {
  final EventItem? existing;
  final Function(EventItem) onSave;
  final bool canManage;

  const _CreateEditEventScreen({this.existing, required this.onSave, required this.canManage});

  @override
  State<_CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<_CreateEditEventScreen> {
  static const Color _primary = Color(0xFF1565C0);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _textDark = Color(0xFF1A237E);

  late TextEditingController titleController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController venueController;
  late TextEditingController organizerController;
  late TextEditingController seatsController;
  
  String _selectedCategory = "Workshop";
  bool _isCollegeEvent = false;

  final List<String> _categories = [
    "Academic", "Workshop", "Seminar", "Placement Drive", "Hackathon", 
    "Sports", "Cultural", "Technical", "Competition", "Guest Lecture", "Festival", "Community Service"
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    titleController = TextEditingController(text: e?.title ?? "");
    dateController = TextEditingController(text: e?.date ?? "");
    timeController = TextEditingController(text: e?.time ?? "");
    venueController = TextEditingController(text: e?.venue ?? "");
    organizerController = TextEditingController(text: e?.organizer ?? "");
    seatsController = TextEditingController(text: e?.totalSeats.toString() ?? "50");
    if (e != null) {
      _selectedCategory = e.category;
      _isCollegeEvent = e.isCollegeEvent;
    }
  }

  void _save({bool isDraft = false}) {
    if (titleController.text.trim().isEmpty || dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Date are required")),
      );
      return;
    }

    String status = isDraft ? "Draft" : (widget.canManage && _isCollegeEvent ? "Registration Open" : "Pending HOD");

    if (widget.existing != null) {
      widget.existing!
        ..title = titleController.text
        ..date = dateController.text
        ..time = timeController.text
        ..venue = venueController.text
        ..organizer = organizerController.text
        ..category = _selectedCategory
        ..isCollegeEvent = _isCollegeEvent
        ..status = status
        ..totalSeats = int.tryParse(seatsController.text) ?? widget.existing!.totalSeats;
    } else {
      widget.onSave(EventItem(
        id: "E${DateTime.now().millisecondsSinceEpoch}",
        title: titleController.text,
        date: dateController.text,
        time: timeController.text,
        venue: venueController.text,
        organizer: organizerController.text,
        category: _selectedCategory,
        isCollegeEvent: _isCollegeEvent,
        status: status,
        totalSeats: int.tryParse(seatsController.text) ?? 50,
        color: _primary, // Default color
      ));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D47A1), _primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        title: Text(isEdit ? "Edit Event" : "Create Event", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Upload Placeholder
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
                  Text("Upload Poster (Future Ready)", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _field("Event Title", titleController, Icons.title_outlined),
            _field("Date (e.g. 25 Dec 2024)", dateController, Icons.calendar_today_outlined),
            _field("Time (e.g. 10:00 AM)", timeController, Icons.access_time_outlined),
            _field("Venue", venueController, Icons.location_on_outlined),
            _field("Organizer", organizerController, Icons.person_outline),
            _field("Total Seats", seatsController, Icons.event_seat_outlined, isNumber: true),
            const SizedBox(height: 16),
            
            // Category Dropdown
            const Text("Category", style: TextStyle(fontWeight: FontWeight.w700, color: _textDark, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // College Event Switch (Only for Principal)
            if (widget.canManage)
              SwitchListTile(
                title: const Text("College Event", style: TextStyle(fontWeight: FontWeight.w700, color: _textDark, fontSize: 14)),
                subtitle: const Text("Requires Principal Approval", style: TextStyle(fontSize: 12)),
                value: _isCollegeEvent,
                onChanged: (val) => setState(() => _isCollegeEvent = val),
                activeColor: _primary,
                contentPadding: EdgeInsets.zero,
              ),

            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _save(isDraft: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Save Draft"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _save(isDraft: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.canManage && _isCollegeEvent ? "Publish" : "Submit for Approval"),
                  ),
                ),
              ],
            )
          ],
        ),
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
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: _primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
  static const Color _primary = Color(0xFF1565C0);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _textDark = Color(0xFF1A237E);

  final Set<String> _approved = {};

  @override
  Widget build(BuildContext context) {
    final students = widget.event.registeredStudents;

    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D47A1), _primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        title: Text("${widget.event.title}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline, color: Colors.white),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard("Total", students.length.toString(), Colors.blue),
                _statCard("Present", _approved.length.toString(), Colors.green),
                _statCard("Absent", (students.length - _approved.length).toString(), Colors.red),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Registered Students", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: students.isEmpty
                ? Center(child: Text("No registrations yet", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final name = students[index];
                      final isApproved = _approved.contains(name);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _primary.withOpacity(0.1),
                              child: Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: _textDark))),
                            isApproved
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Text("Present", style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
                                  )
                                : ElevatedButton(
                                    onPressed: () => setState(() => _approved.add(name)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text("Mark Present"),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}