import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class NoticeScreen extends StatefulWidget {
  final UserRole userRole;

  const NoticeScreen({super.key, this.userRole = UserRole.student});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _canApprove => _currentUser?.role == UserRole.hod || _currentUser?.role == UserRole.principal;

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ["All", "Academic", "Examination", "Placement", "Events", "Emergency"];

  // 👇 FIX: Made notices mutable (not final) so we can change their status
  late List<Map<String, dynamic>> _allNotices;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    _allNotices = [
      {"id": "N1", "title": "Low Attendance Warning", "desc": "Your attendance in DBMS is below 75%.", "cat": "Academic", "priority": "High", "time": "10:30 AM", "status": "Published", "isPinned": false},
      {"id": "N2", "title": "TCS Placement Drive", "desc": "TCS visiting campus on 15th Dec.", "cat": "Placement", "priority": "High", "time": "Yesterday", "status": "Published", "isPinned": false},
      {"id": "N3", "title": "Tech Fest 2024 Draft", "desc": "Draft for tech fest event.", "cat": "Events", "priority": "Medium", "time": "10:00 AM", "status": "Pending HOD", "isPinned": false},
      {"id": "N4", "title": "Library Book Due", "desc": "Return 'Clean Code' tomorrow.", "cat": "Academic", "priority": "Medium", "time": "09:00 AM", "status": "Pending Principal", "isPinned": false},
    ];
  }

  // 👇 FIX: Actual Logic to Approve Notice
  void _approveNotice(Map<String, dynamic> notice) {
    setState(() {
      if (notice['status'] == 'Pending HOD') {
        notice['status'] = 'Pending Principal'; // HOD approved, send to Principal
      } else if (notice['status'] == 'Pending Principal') {
        notice['status'] = 'Published'; // Principal approved, make it public
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Notice Status Updated to: ${notice['status']}"), backgroundColor: Colors.green),
    );
  }

  // 👇 FIX: Actual Logic to Reject Notice
  void _rejectNotice(Map<String, dynamic> notice) {
    setState(() {
      _allNotices.remove(notice); // Remove from list
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notice Rejected & Removed"), backgroundColor: Colors.red),
    );
  }

  List<Map<String, dynamic>> get _filteredNotices {
    return _allNotices.where((n) {
      // Role Filter: Students only see Published
      if (!_canApprove && n['status'] != 'Published') return false;

      // Category Filter
      if (_selectedCategoryIndex != 0 && n['cat'] != _categories[_selectedCategoryIndex]) return false;

      // Search Filter
      if (_searchController.text.isNotEmpty) {
        return (n['title'] as String).toLowerCase().contains(_searchController.text.toLowerCase());
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filteredNotices;
    final pendingApprovals = notifications.where((n) => n['status'] == 'Pending HOD' || n['status'] == 'Pending Principal').toList();
    final publishedNotices = notifications.where((n) => n['status'] == 'Published').toList();

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
        title: const Text("Notices & Circulars", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search notices...",
                prefixIcon: const Icon(Icons.search, color: _primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
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
                      color: isSelected ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                    ),
                    child: Center(child: Text(_categories[index], style: TextStyle(color: isSelected ? Colors.white : _textDark, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notifications.isEmpty
                ? Center(child: Text("No notices found", style: TextStyle(color: Colors.grey.shade400)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (_canApprove && pendingApprovals.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 12),
                          child: Text("PENDING APPROVALS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        ...pendingApprovals.map((n) => _buildNoticeCard(n)).toList(),
                        const SizedBox(height: 20),
                      ],
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 12),
                        child: Text("PUBLISHED NOTICES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      ...publishedNotices.map((n) => _buildNoticeCard(n)).toList(),
                    ],
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> n) {
    bool isPending = n['status'] == 'Pending HOD' || n['status'] == 'Pending Principal';
    Color statusColor = isPending ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBlue, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(n['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(n['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(n['desc'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(n['time'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
              
              // 👇 FIX: Action Buttons working properly
              if (_canApprove && isPending)
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _rejectNotice(n),
                      child: const Text("Reject", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approveNotice(n),
                      style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                      child: const Text("Approve"),
                    ),
                  ],
                ),
            ],
          )
        ],
      ),
    );
  }
}