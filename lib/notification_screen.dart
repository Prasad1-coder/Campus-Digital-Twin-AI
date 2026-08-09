import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  UserRole get _userRole => _currentUser?.role ?? UserRole.student;

  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    "All", "Academic", "Attendance", "Placement", "Library", 
    "Events", "Canteen", "Fees", "Emergency", "System"
  ];

  // ---------- Dummy Data ----------
  final List<Map<String, dynamic>> _allNotifications = [
    // Student Specific
    {"id": "N1", "title": "Low Attendance Warning", "msg": "Your attendance in DBMS is below 75%. Please attend the next lecture.", "cat": "Attendance", "priority": "High", "time": "10:30 AM", "date": "Today", "isRead": false, "isPinned": false, "roles": [UserRole.student]},
    {"id": "N2", "title": "Library Book Due", "msg": "'Clean Code' is due tomorrow. Please return it to avoid fine.", "cat": "Library", "priority": "Medium", "time": "09:15 AM", "date": "Today", "isRead": false, "isPinned": false, "roles": [UserRole.student, UserRole.teacher]},
    {"id": "N3", "title": "TCS Placement Drive", "msg": "TCS is visiting campus on 15th Dec. Register before 12th Dec.", "cat": "Placement", "priority": "High", "time": "Yesterday", "date": "Yesterday", "isRead": true, "isPinned": false, "roles": [UserRole.student]},
    {"id": "N4", "title": "Timetable Changed", "msg": "Tomorrow's DBMS lecture is rescheduled to 2:00 PM.", "cat": "Academic", "priority": "Medium", "time": "Yesterday", "date": "Yesterday", "isRead": false, "isPinned": false, "roles": [UserRole.student, UserRole.teacher]},
    
    // Teacher Specific
    {"id": "N5", "title": "Pending Attendance", "msg": "You have not marked attendance for SE Computer Div A (9:00 AM).", "cat": "Attendance", "priority": "High", "time": "11:00 AM", "date": "Today", "isRead": false, "isPinned": false, "roles": [UserRole.teacher, UserRole.hod]},
    {"id": "N6", "title": "Department Meeting", "msg": "HOD has scheduled a department meeting at 3:00 PM in the cabin.", "cat": "Academic", "priority": "Medium", "time": "10:00 AM", "date": "Today", "isRead": false, "isPinned": false, "roles": [UserRole.teacher]},
    
    // HOD Specific
    {"id": "N7", "title": "Approval Request: Tech Fest", "msg": "Prof. Sharma has submitted a draft notice for Tech Fest 2024.", "cat": "System", "priority": "Medium", "time": "08:45 AM", "date": "Today", "isRead": false, "isPinned": false, "roles": [UserRole.hod]},
    {"id": "N8", "title": "Dept Analytics Ready", "msg": "Monthly department attendance analytics report is ready to view.", "cat": "Academic", "priority": "Low", "time": "Yesterday", "date": "Yesterday", "isRead": true, "isPinned": false, "roles": [UserRole.hod, UserRole.principal]},
    
    // Principal Specific
    {"id": "N9", "title": "Emergency: Power Outage", "msg": "Main power grid is down. Generator backup activated. Classes suspended till 12 PM.", "cat": "Emergency", "priority": "Critical", "time": "09:00 AM", "date": "Today", "isRead": false, "isPinned": true, "roles": [UserRole.principal, UserRole.hod, UserRole.teacher, UserRole.student]},
    {"id": "N10", "title": "Monthly College Report", "msg": "The monthly performance and placement report is ready for review.", "cat": "System", "priority": "Medium", "time": "2 days ago", "date": "Earlier", "isRead": true, "isPinned": false, "roles": [UserRole.principal]},
    
    // Common
    {"id": "N11", "title": "Canteen Special Menu", "msg": "Today's special: Veg Biryani and Ice Cream! Available from 12 PM.", "cat": "Canteen", "priority": "Low", "time": "08:00 AM", "date": "Today", "isRead": false, "isPinned": false, "roles": [UserRole.student, UserRole.teacher, UserRole.hod, UserRole.principal]},
    {"id": "N12", "title": "Fee Payment Reminder", "msg": "Semester 6 fee payment due is approaching. Pay before 20th Dec.", "cat": "Fees", "priority": "High", "time": "3 days ago", "date": "Earlier", "isRead": true, "isPinned": false, "roles": [UserRole.student]},
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    return _allNotifications.where((n) {
      // Role Filter
      bool hasRoleAccess = (n['roles'] as List).contains(_userRole);
      if (!hasRoleAccess) return false;

      // Category Filter
      if (_selectedCategoryIndex != 0 && n['cat'] != _categories[_selectedCategoryIndex]) {
        return false;
      }

      // Search Filter
      if (_searchController.text.isNotEmpty) {
        return (n['title'] as String).toLowerCase().contains(_searchController.text.toLowerCase()) ||
               (n['msg'] as String).toLowerCase().contains(_searchController.text.toLowerCase());
      }

      return true;
    }).toList();
  }

  void _markAllRead() {
    setState(() {
      for (var n in _filteredNotifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All notifications marked as read"), duration: Duration(seconds: 1)),
    );
  }

  void _togglePin(Map<String, dynamic> notification) {
    setState(() {
      notification['isPinned'] = !notification['isPinned'];
    });
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    setState(() {
      _allNotifications.remove(notification);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification deleted"), duration: Duration(seconds: 1)),
    );
  }

  void _toggleRead(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = !notification['isRead'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filteredNotifications;
    final pinnedList = notifications.where((n) => n['isPinned'] == true).toList();
    final todayList = notifications.where((n) => n['date'] == 'Today' && n['isPinned'] == false).toList();
    final yesterdayList = notifications.where((n) => n['date'] == 'Yesterday' && n['isPinned'] == false).toList();
    final earlierList = notifications.where((n) => n['date'] == 'Earlier' && n['isPinned'] == false).toList();

    int unreadCount = notifications.where((n) => n['isRead'] == false).length;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
            Text("$unreadCount Unread Notifications", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            tooltip: "Mark all read",
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildCategoryChips(),
          const SizedBox(height: 12),
          Expanded(
            child: notifications.isEmpty
                ? Center(child: Text("No notifications found", style: TextStyle(color: Colors.grey.shade400)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (pinnedList.isNotEmpty) ...[
                        _buildSectionHeader("Pinned"),
                        ...pinnedList.map((n) => _buildNotificationCard(n)).toList(),
                        const SizedBox(height: 16),
                      ],
                      if (todayList.isNotEmpty) ...[
                        _buildSectionHeader("Today"),
                        ...todayList.map((n) => _buildNotificationCard(n)).toList(),
                        const SizedBox(height: 16),
                      ],
                      if (yesterdayList.isNotEmpty) ...[
                        _buildSectionHeader("Yesterday"),
                        ...yesterdayList.map((n) => _buildNotificationCard(n)).toList(),
                        const SizedBox(height: 16),
                      ],
                      if (earlierList.isNotEmpty) ...[
                        _buildSectionHeader("Earlier"),
                        ...earlierList.map((n) => _buildNotificationCard(n)).toList(),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  WIDGETS
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: "Search notifications...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: _primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    bool isRead = n['isRead'] as bool;
    bool isPinned = n['isPinned'] as bool;
    String priority = n['priority'] as String;
    String cat = n['cat'] as String;

    Color priorityColor = Colors.blue;
    if (priority == 'High') priorityColor = Colors.orange;
    if (priority == 'Critical') priorityColor = Colors.red;
    if (priority == 'Low') priorityColor = Colors.grey;

    IconData catIcon = Icons.notifications_outlined;
    if (cat == 'Attendance') catIcon = Icons.fact_check_outlined;
    if (cat == 'Library') catIcon = Icons.menu_book_outlined;
    if (cat == 'Placement') catIcon = Icons.work_outline;
    if (cat == 'Emergency') catIcon = Icons.warning_amber_rounded;
    if (cat == 'Canteen') catIcon = Icons.restaurant_outlined;
    if (cat == 'Fees') catIcon = Icons.account_balance_wallet_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : _softBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPinned ? _primary.withOpacity(0.3) : Colors.grey.shade100, width: isPinned ? 1.5 : 1),
        boxShadow: [
          if (!isRead) 
            BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
          else 
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Dismissible(
        key: Key(n['id'] as String),
        direction: DismissDirection.horizontal,
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.push_pin_rounded, color: Colors.white),
        ),
        secondaryBackground: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            _deleteNotification(n);
          } else {
            _togglePin(n);
          }
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _toggleRead(n),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(catIcon, color: priorityColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n['title'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: _textDark,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                              )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n['msg'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: priorityColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${n['date']} • ${n['time']}",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if (isPinned)
                              const Icon(Icons.push_pin_rounded, size: 14, color: _primary),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}