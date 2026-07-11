import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // for share
import 'profile_screen.dart'; // we connect to profile

enum NoticeCategory { exam, placement, holiday, circular, event }

extension NoticeCategoryX on NoticeCategory {
  String get label {
    switch (this) {
      case NoticeCategory.exam:
        return "Exam";
      case NoticeCategory.placement:
        return "Placement";
      case NoticeCategory.holiday:
        return "Holiday";
      case NoticeCategory.circular:
        return "Circular";
      case NoticeCategory.event:
        return "Event";
    }
  }

  Color get color {
    switch (this) {
      case NoticeCategory.exam:
        return Colors.red;
      case NoticeCategory.placement:
        return Colors.green;
      case NoticeCategory.holiday:
        return Colors.orange;
      case NoticeCategory.circular:
        return Colors.blue;
      case NoticeCategory.event:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case NoticeCategory.exam:
        return Icons.edit_document;
      case NoticeCategory.placement:
        return Icons.work_outline;
      case NoticeCategory.holiday:
        return Icons.beach_access_outlined;
      case NoticeCategory.circular:
        return Icons.description_outlined;
      case NoticeCategory.event:
        return Icons.celebration_outlined;
    }
  }
}

class NoticeItem {
  String title;
  String content;
  String postedBy;
  DateTime dateTime;
  NoticeCategory category;
  bool isPinned;
  bool isUrgent;
  bool isImportant;
  bool hasPdf;

  NoticeItem({
    required this.title,
    required this.content,
    required this.postedBy,
    required this.dateTime,
    required this.category,
    this.isPinned = false,
    this.isUrgent = false,
    this.isImportant = false,
    this.hasPdf = false,
  });
}

class _NoticeStore {
  static final List<NoticeItem> notices = [
    NoticeItem(
      title: "Semester End Exam Timetable Released",
      content: "All students are informed that the semester end examination timetable has been released. Please check the notice board and download your respective timetable. Exams will commence from 5th August 2026.",
      postedBy: "Exam Cell",
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      category: NoticeCategory.exam,
      isPinned: true,
      isUrgent: true,
      hasPdf: true,
    ),
    NoticeItem(
      title: "TCS Campus Placement Drive",
      content: "TCS is conducting a campus placement drive for final year students on 20th July 2026. Eligible students must register before 15th July. Bring updated resume and college ID.",
      postedBy: "Placement Cell",
      dateTime: DateTime.now().subtract(const Duration(hours: 6)),
      category: NoticeCategory.placement,
      isImportant: true,
      hasPdf: true,
    ),
    NoticeItem(
      title: "College Holiday - Independence Day",
      content: "College will remain closed on 15th August 2026 on account of Independence Day. Flag hoisting ceremony will be held at 8 AM in the main ground.",
      postedBy: "Admin Office",
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      category: NoticeCategory.holiday,
    ),
    NoticeItem(
      title: "Fee Payment Circular - Semester 4",
      content: "All students of semester 4 are required to pay their remaining fees before 25th July 2026 to avoid late fine. Payment can be made online through the college portal.",
      postedBy: "Accounts Office",
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      category: NoticeCategory.circular,
      hasPdf: true,
    ),
    NoticeItem(
      title: "TechFest 2026 Registrations Open",
      content: "Registrations for TechFest 2026 Hackathon are now open. Team size: 2-4 members. Register through the Events section of this app.",
      postedBy: "Computer Dept",
      dateTime: DateTime.now().subtract(const Duration(days: 3)),
      category: NoticeCategory.event,
    ),
  ];

  static void sortNotices() {
    notices.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.dateTime.compareTo(a.dateTime);
    });
  }
}

class NoticeScreen extends StatefulWidget {
  final UserRole userRole;

  const NoticeScreen({super.key, this.userRole = UserRole.student});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  NoticeCategory? selectedCategory;

  bool get isAdmin => widget.userRole == UserRole.teacher;

  List<NoticeItem> get _filtered {
    _NoticeStore.sortNotices();
    return _NoticeStore.notices.where((n) {
      final matchesSearch = n.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          n.content.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null || n.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  void _togglePin(NoticeItem notice) {
    setState(() => notice.isPinned = !notice.isPinned);
  }

  void _deleteNotice(NoticeItem notice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Notice?"),
        content: Text("\"${notice.title}\" ko delete karna hai?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => _NoticeStore.notices.remove(notice));
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _sendNotification(NoticeItem notice) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🔔 Notification sent to all students for \"${notice.title}\""),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  void _openCreateOrEdit({NoticeItem? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateEditNoticeScreen(
          existing: existing,
          onSave: (notice) {
            setState(() {
              if (existing == null) _NoticeStore.notices.add(notice);
            });
          },
        ),
      ),
    );
  }

  void _openDetail(NoticeItem notice) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _NoticeDetailScreen(notice: notice)),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notices = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notice Board", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      "${_NoticeStore.notices.where((n) => n.isUrgent).length}",
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text("Add Notice", style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () => _openCreateOrEdit(),
            )
          : null,
      body: Column(
        children: [
          // 👇 Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => searchQuery = v),
                decoration: InputDecoration(
                  hintText: "Search notices...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchQuery = "");
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // 👇 Category filter chips
          SizedBox(
            height: 42,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: "All",
                  color: Colors.blue,
                  isSelected: selectedCategory == null,
                  onTap: () => setState(() => selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...NoticeCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: cat.label,
                        color: cat.color,
                        isSelected: selectedCategory == cat,
                        onTap: () => setState(() => selectedCategory = cat),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: notices.isEmpty
                ? Center(child: Text("Koi notice nahi mila", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 90),
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final notice = notices[index];
                      return _NoticeCard(
                        notice: notice,
                        isAdmin: isAdmin,
                        onTap: () => _openDetail(notice),
                        onPin: () => _togglePin(notice),
                        onEdit: () => _openCreateOrEdit(existing: notice),
                        onDelete: () => _deleteNotice(notice),
                        onNotify: () => _sendNotification(notice),
                        onShare: () => Share.share("${notice.title}\n\n${notice.content}\n\n- ${notice.postedBy}"),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade700),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final NoticeItem notice;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onNotify;
  final VoidCallback onShare;

  const _NoticeCard({
    required this.notice,
    required this.isAdmin,
    required this.onTap,
    required this.onPin,
    required this.onEdit,
    required this.onDelete,
    required this.onNotify,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final cat = notice.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: notice.isUrgent ? Colors.red.shade200 : Colors.grey.shade200,
          width: notice.isUrgent ? 1.4 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (notice.isPinned) ...[
                      Icon(Icons.push_pin, size: 14, color: Colors.blue.shade600),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: cat.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 11, color: cat.color),
                          const SizedBox(width: 4),
                          Text(cat.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: cat.color)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (notice.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                        child: const Text("URGENT", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    if (notice.isImportant) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded, size: 16, color: Colors.orange.shade600),
                    ],
                    const Spacer(),
                    Text(_timeAgoStatic(notice.dateTime), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  notice.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  notice.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(notice.postedBy, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    if (notice.hasPdf) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.picture_as_pdf_outlined, size: 13, color: Colors.red.shade400),
                      const SizedBox(width: 3),
                      Text("PDF", style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                    ],
                    const Spacer(),
                    if (isAdmin) ...[
                      _iconBtn(Icons.notifications_active_outlined, Colors.blue, onNotify, "Notify"),
                      _iconBtn(notice.isPinned ? Icons.push_pin : Icons.push_pin_outlined, Colors.blue, onPin, "Pin"),
                      _iconBtn(Icons.edit_outlined, Colors.grey.shade700, onEdit, "Edit"),
                      _iconBtn(Icons.delete_outline, Colors.red, onDelete, "Delete"),
                    ] else
                      _iconBtn(Icons.share_outlined, Colors.grey.shade600, onShare, "Share"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  String _timeAgoStatic(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

// ============================================================
// NOTICE DETAIL SCREEN (Read More)
// ============================================================
class _NoticeDetailScreen extends StatelessWidget {
  final NoticeItem notice;
  const _NoticeDetailScreen({required this.notice});

  @override
  Widget build(BuildContext context) {
    final cat = notice.category;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notice"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share("${notice.title}\n\n${notice.content}\n\n- ${notice.postedBy}"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: cat.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 13, color: cat.color),
                    const SizedBox(width: 5),
                    Text(cat.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cat.color)),
                  ],
                ),
              ),
              if (notice.isUrgent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: const Text("URGENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(notice.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(notice.postedBy, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(width: 14),
              Icon(Icons.access_time, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(
                "${notice.dateTime.day}/${notice.dateTime.month}/${notice.dateTime.year}",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(notice.content, style: const TextStyle(fontSize: 14.5, height: 1.7, color: Colors.black87)),
          ),
          if (notice.hasPdf) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("📥 PDF download coming soon")),
                  );
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text("Download PDF"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Colors.blue),
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// CREATE / EDIT NOTICE SCREEN (Admin)
// ============================================================
class _CreateEditNoticeScreen extends StatefulWidget {
  final NoticeItem? existing;
  final Function(NoticeItem) onSave;

  const _CreateEditNoticeScreen({this.existing, required this.onSave});

  @override
  State<_CreateEditNoticeScreen> createState() => _CreateEditNoticeScreenState();
}

class _CreateEditNoticeScreenState extends State<_CreateEditNoticeScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController postedByController;
  late NoticeCategory category;
  late bool isPinned;
  late bool isUrgent;
  late bool isImportant;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    titleController = TextEditingController(text: e?.title ?? "");
    contentController = TextEditingController(text: e?.content ?? "");
    postedByController = TextEditingController(text: e?.postedBy ?? "");
    category = e?.category ?? NoticeCategory.circular;
    isPinned = e?.isPinned ?? false;
    isUrgent = e?.isUrgent ?? false;
    isImportant = e?.isImportant ?? false;
  }

  void _save() {
    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title aur content bharo")));
      return;
    }

    if (widget.existing != null) {
      widget.existing!
        ..title = titleController.text
        ..content = contentController.text
        ..postedBy = postedByController.text
        ..category = category
        ..isPinned = isPinned
        ..isUrgent = isUrgent
        ..isImportant = isImportant;
    } else {
      widget.onSave(NoticeItem(
        title: titleController.text,
        content: contentController.text,
        postedBy: postedByController.text.isEmpty ? "Admin" : postedByController.text,
        dateTime: DateTime.now(),
        category: category,
        isPinned: isPinned,
        isUrgent: isUrgent,
        isImportant: isImportant,
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
        title: Text(isEdit ? "Edit Notice" : "Add Notice"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field("Notice Title", titleController, Icons.title_outlined),
          _field("Content", contentController, Icons.notes_outlined, maxLines: 5),
          _field("Posted By", postedByController, Icons.person_outline),
          const SizedBox(height: 8),

          Text("Category", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NoticeCategory.values.map((cat) {
              final selected = category == cat;
              return GestureDetector(
                onTap: () => setState(() => category = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? cat.color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? cat.color : Colors.grey.shade300),
                  ),
                  child: Text(cat.label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 12.5)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Pin this notice", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  secondary: const Icon(Icons.push_pin_outlined, color: Colors.blue),
                  value: isPinned,
                  activeColor: Colors.blue,
                  onChanged: (v) => setState(() => isPinned = v),
                ),
                SwitchListTile(
                  title: const Text("Mark as urgent", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  secondary: const Icon(Icons.priority_high_rounded, color: Colors.red),
                  value: isUrgent,
                  activeColor: Colors.red,
                  onChanged: (v) => setState(() => isUrgent = v),
                ),
                SwitchListTile(
                  title: const Text("Mark as important", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  secondary: const Icon(Icons.star_outline, color: Colors.orange),
                  value: isImportant,
                  activeColor: Colors.orange,
                  onChanged: (v) => setState(() => isImportant = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 👇 Upload placeholders
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📎 PDF upload coming soon")));
                  },
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text("Upload PDF"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📷 Image upload coming soon")));
                  },
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text("Upload Image"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEdit ? "Update Notice" : "Post Notice"),
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

  Widget _field(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}