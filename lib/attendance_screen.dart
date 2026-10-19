import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'services/auth_service.dart';
import 'user_role.dart';

// ======================= THEME / CONSTANTS =======================
const _primary = Color(0xFF1565C0);
const _primaryDark = Color(0xFF0D47A1);
const _accent = Color(0xFF42A5F5);
const _lightBg = Color(0xFFF5F9FF);
const _softBlue = Color(0xFFE3F2FD);
const _textDark = Color(0xFF1A237E);

const _qrPrefix = "CDT-ATT:";
const _sessionMinutes = 15;
const _onTimeGraceMinutes = 10;
const _classroomRadiusMeters = 100.0;

bool _dark(ThemeData t) => t.brightness == Brightness.dark;
Color _tintOf(ThemeData t) => _dark(t) ? _primary.withOpacity(0.20) : _softBlue;
Color _iconOf(ThemeData t) => _dark(t) ? _accent : _primary;
Color _headingOf(ThemeData t) => _dark(t) ? t.colorScheme.onSurface : _textDark;

// ======================= SHARED HELPERS =======================
FirebaseFirestore get _db => FirebaseFirestore.instance;

TextStyle _ts(double size, int w, Color c, {double? h}) =>
    TextStyle(fontSize: size, fontWeight: FontWeight.values[w ~/ 100 - 1], color: c, height: h);

BoxDecoration _cardDeco(ThemeData t, {double r = 20, List<BoxShadow>? shadow}) => BoxDecoration(
      color: t.cardColor,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: t.dividerColor.withOpacity(0.6)),
      boxShadow: shadow,
    );

ButtonStyle _btn({double pad = 14, double r = 16}) => ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: pad),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
    );

Widget _iconBox(IconData icon, Color c, {double size = 42, double iconSize = 22, double r = 13, Color? bg}) =>
    Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg ?? c.withOpacity(0.12), borderRadius: BorderRadius.circular(r)),
      child: Icon(icon, color: c, size: iconSize),
    );

Widget _pill(String text, Color c, {Color? bg, double fs = 12, double r = 10, double h = 10, double v = 5, IconData? icon}) =>
    Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: v),
      decoration: BoxDecoration(color: bg ?? c.withOpacity(0.12), borderRadius: BorderRadius.circular(r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 15, color: c), const SizedBox(width: 4)],
        Text(text, style: _ts(fs, 800, c)),
      ]),
    );

Widget _bar(double v, Color c, {double h = 7, Color? bg}) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(value: v, minHeight: h, backgroundColor: bg ?? c.withOpacity(0.12), valueColor: AlwaysStoppedAnimation(c)),
    );

Widget _sectionTitle(BuildContext c, String title) => Text(title, style: _ts(18, 800, _headingOf(Theme.of(c))));

Widget _groupedCard(BuildContext c, List<Widget> rows) {
  final t = Theme.of(c);
  return Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: _cardDeco(t),
    child: Material(
      color: Colors.transparent,
      child: Column(children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: t.dividerColor.withOpacity(0.7)),
          rows[i],
        ],
      ]),
    ),
  );
}

Widget _emptyNote(BuildContext c, IconData icon, String text) {
  final t = Theme.of(c);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _cardDeco(t),
    child: Row(children: [
      Icon(icon, color: t.hintColor, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: _ts(13, 400, t.hintColor, h: 1.35))),
    ]),
  );
}

Widget _rowTile(BuildContext c, IconData icon, Color color, String title, String? sub, Widget trailing, {bool big = false}) {
  final t = Theme.of(c);
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: big ? 16 : 14, vertical: big ? 12 : 11),
    child: Row(children: [
      _iconBox(icon, color, size: big ? 42 : 38, iconSize: big ? 22 : 20, r: big ? 13 : 12),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(14.5, 700, big ? _headingOf(t) : t.colorScheme.onSurface)),
          if (sub != null && sub.isNotEmpty) Text(sub, style: _ts(12, 400, t.hintColor)),
        ]),
      ),
      trailing,
    ]),
  );
}

Widget _sheetFrame(BuildContext ctx, {required double h, required String title, required String sub, Widget? extra, required Widget body, required Widget footer}) {
  final t = Theme.of(ctx);
  return Container(
    height: MediaQuery.of(ctx).size.height * h,
    decoration: BoxDecoration(
      color: _dark(t) ? t.scaffoldBackgroundColor : _lightBg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_primaryDark, _primary], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: _ts(18, 800, Colors.white)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(13, 400, Colors.white70)),
              ]),
            ),
            IconButton(tooltip: "Close", icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
          ]),
          if (extra != null) ...[const SizedBox(height: 12), extra],
        ]),
      ),
      Expanded(child: body),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: SizedBox(width: double.infinity, child: footer))),
    ]),
  );
}

String _randomString(int len, String chars, Random r) => List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
String _randomCode() => _randomString(6, 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789', Random());
String _randomToken() => _randomString(24, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789', Random.secure());

String _dateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
String _formatTime(DateTime d) =>
    "${d.hour % 12 == 0 ? 12 : d.hour % 12}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}";
String _formatDate(DateTime d) =>
    "${d.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}";
DateTime _markedAtOf(Map<String, dynamic> d) => (d['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

DateTime? _parseHHmm(String? hhmm, String yyyyMMdd) {
  if (hhmm == null || hhmm.isEmpty) return null;
  try {
    final d = yyyyMMdd.split('-').map(int.parse).toList();
    final t = hhmm.split(':').map(int.parse).toList();
    return (d.length != 3 || t.length < 2) ? null : DateTime(d[0], d[1], d[2], t[0], t[1]);
  } catch (_) {
    return null;
  }
}

bool _sessionIsActive(Map<String, dynamic> d) {
  final s = (d['status'] ?? '').toString();
  return s.isNotEmpty ? (s == 'active' || s == 'open') : d['active'] == true;
}

String _computeStatus(DateTime? start) =>
    (start == null || DateTime.now().difference(start).inMinutes <= _onTimeGraceMinutes) ? 'present' : 'late';

bool _isTimeVerified(DateTime? start, DateTime? end) {
  if (start == null) return false;
  final now = DateTime.now();
  return now.isAfter(start.subtract(const Duration(minutes: 15))) &&
      now.isBefore((end ?? start.add(const Duration(hours: 1))).add(const Duration(minutes: 15)));
}

/// Firestore session document (token != null => live QR session, else closed manual session)
Map<String, dynamic> _sessionData(Map<String, dynamic> c, dynamic user, String id, DateTime now, {String? token}) {
  final manual = token == null;
  return {
    'sessionId': id, 'scheduleId': null,
    'subjectId': c['subjectId'], 'subjectName': c['subject'],
    'teacherId': user.id, 'teacherName': user.fullName,
    'departmentId': c['departmentId'], 'semester': c['semester'],
    'divisionId': c['divisionId'], 'academicYear': c['academicYear'],
    'roomId': c['roomId'], 'roomName': c['room'],
    'classDate': _dateKey(now),
    'classStartTime': c['classStartTime'], 'classEndTime': c['classEndTime'],
    'classroomLat': c['classroomLat'], 'classroomLng': c['classroomLng'],
    'openedAt': FieldValue.serverTimestamp(),
    'expiresAt': manual ? null : Timestamp.fromDate(now.add(const Duration(minutes: _sessionMinutes))),
    'closedAt': manual ? FieldValue.serverTimestamp() : null,
    'status': manual ? 'closed' : 'active', 'active': !manual,
    'securityToken': token, 'qrVersion': manual ? 0 : 1,
    'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Firestore attendance record built from a session map
Map<String, dynamic> _record(Map<String, dynamic> s, String studentId, String name, String collegeId, String status, String method,
        Map<String, dynamic> verification, Map<String, dynamic>? location) =>
    {
      'recordId': '${s['sessionId']}_$studentId',
      'sessionId': s['sessionId'], 'studentId': studentId, 'studentName': name, 'collegeId': collegeId,
      for (final k in ['subjectId', 'subjectName', 'teacherId', 'teacherName', 'departmentId', 'semester', 'divisionId', 'academicYear', 'roomId', 'roomName', 'classDate', 'classStartTime', 'classEndTime']) k: s[k],
      'markedAt': FieldValue.serverTimestamp(), 'status': status, 'method': method,
      'verification': verification, 'location': location,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    };

Map<String, dynamic> _verif({bool qr = false, bool student = false, bool time = false, bool loc = false, double? acc, bool gps = false}) => {
      'qrVerified': qr, 'studentVerified': student, 'classVerified': true, 'timeVerified': time,
      'locationVerified': loc, 'locationAccuracy': acc, 'proximityMethod': gps ? 'gps' : 'none',
    };

// ======================= SCREEN =======================
class AttendanceScreen extends StatefulWidget {
  final UserRole userRole;
  final String currentUserName;

  const AttendanceScreen({super.key, required this.userRole, required this.currentUserName});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _auth = AuthService();

  bool get isStudent => widget.userRole == UserRole.student;
  bool get canTeach => widget.userRole == UserRole.teacher || widget.userRole == UserRole.hod;

  static const _overall = 82;

  // (name, code, att%, total, present, faculty, color)
  static const _subjects = [
    ("Data Structures", "CS201", 85, 40, 34, "Dr. Sharma", Colors.blue),
    ("Operating Systems", "CS202", 72, 40, 29, "Dr. Rao", Colors.purple),
    ("DBMS", "CS203", 91, 38, 35, "Prof. Singh", Colors.green),
    ("Computer Networks", "CS204", 68, 42, 29, "Dr. Mehta", Colors.orange),
  ];

  static const _deptStats = [
    ("Computer Eng", 89, Colors.blue),
    ("Mechanical", 76, Colors.orange),
    ("Civil", 82, Colors.green),
    ("Electrical", 71, Colors.red),
  ];

  static Map<String, dynamic> _cls(String id, String subject, String div, String roomId, String room, String start, String end,
          String time, int total, int present) =>
      {
        "subjectId": id, "subject": subject, "departmentId": "CS", "semester": 6, "divisionId": div,
        "academicYear": "2026-27", "teacherId": "", "roomId": roomId, "room": room,
        "classStartTime": start, "classEndTime": end, "year": "B.Sc CS – 3rd Year", "time": time,
        "total": total, "present": present, "absent": total - present,
        "classroomLat": 19.17472, "classroomLng": 77.30028, // Science College Nanded
      };

  static final _teacherClasses = [
    _cls("CS201", "Data Structures", "A", "ROOM204", "204", "09:00", "10:00", "09:00 AM", 60, 55),
    _cls("CS202", "Advanced Java", "A", "ROOM301", "301", "11:00", "12:00", "11:00 AM", 55, 50),
    _cls("CS203", "DBMS Lab", "B", "LAB1", "Lab 1", "14:00", "15:00", "02:00 PM", 30, 28),
  ];

  List<(String, String, IconData, Color)> get _strip {
    if (isStudent) {
      final atRisk = _subjects.where((s) => s.$3 < 75).length;
      final best = _subjects.map((s) => s.$3).reduce(max);
      return [
        ("${_subjects.length}", "Subjects", Icons.menu_book_outlined, Colors.blue),
        ("$atRisk", "Below 75%", Icons.warning_amber_rounded, atRisk > 0 ? Colors.red : Colors.green),
        ("$best%", "Best subject", Icons.emoji_events_outlined, Colors.green),
      ];
    }
    if (canTeach) {
      return [
        ("3", "Classes Today", Icons.class_outlined, Colors.blue),
        ("133", "Students Marked", Icons.people_alt_outlined, Colors.teal),
        ("1", "Pending", Icons.pending_actions, Colors.orange),
        ("87%", "Avg Attendance", Icons.percent, Colors.green),
      ];
    }
    return [
      ("84%", "Overall Att", Icons.percent, Colors.green),
      ("142", "Defaulters", Icons.warning_amber_rounded, Colors.red),
      ("45", "Classes Today", Icons.class_outlined, Colors.blue),
    ];
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _showSheet(WidgetBuilder b) =>
      showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: b);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _dark(t) ? t.scaffoldBackgroundColor : _lightBg,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              _header(),
              Positioned(left: 18, right: 18, bottom: -46, child: _statsStrip(_strip)),
            ]),
            const SizedBox(height: 68),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: isStudent ? _studentView() : (canTeach ? _teacherView() : _adminView()),
            ),
          ]),
        ),
      ),
    );
  }

  // ======================= HEADER =======================
  Widget _header() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, _accent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _HeaderGridPainter())),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 64),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (Navigator.of(context).canPop()) ...[
                  _headerBtn(Icons.arrow_back_ios_new_rounded, "Back", () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                ],
                Expanded(child: Text(isStudent ? "My Attendance" : "Attendance Management", maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(18, 800, Colors.white))),
                _headerBtn(Icons.filter_list_rounded, "Filter", () {}),
                if (_auth.hasPermission('attendance', 'canExport')) ...[
                  const SizedBox(width: 8),
                  _headerBtn(Icons.download_outlined, "Export report", () => _snack("Exporting report... (UI Placeholder)")),
                ],
              ]),
              const SizedBox(height: 20),
              isStudent ? _studentHero() : (canTeach ? _teacherHero() : _adminHero()),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _headerBtn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: Material(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onTap,
            child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white, size: 20)),
          ),
        ),
      );

  Widget _studentHero() {
    final low = _overall < 75;
    final c = low ? Colors.red.shade700 : Colors.green.shade700;
    return Row(children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: _overall / 100),
        duration: const Duration(seconds: 1),
        builder: (_, v, __) => SizedBox(
          width: 112,
          height: 112,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(
              child: CircularProgressIndicator(value: v, strokeWidth: 10, strokeCap: StrokeCap.round, backgroundColor: Colors.white24, color: low ? Colors.redAccent : Colors.greenAccent),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text("${(v * 100).toInt()}%", style: _ts(28, 800, Colors.white)),
              Text("Overall", style: _ts(11.5, 400, Colors.white70)),
            ]),
          ]),
        ),
      ),
      const SizedBox(width: 18),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.currentUserName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(18, 800, Colors.white)),
          const SizedBox(height: 3),
          Text("Overall attendance", style: _ts(12.5, 400, Colors.white70)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(low ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: c, size: 16),
              const SizedBox(width: 6),
              Flexible(child: Text(low ? "Low Attendance! Defaulter Risk." : "Good Standing! Keep it up.", style: _ts(12, 700, c))),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _teacherHero() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Hello, ${widget.currentUserName}", maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(22, 800, Colors.white)),
        const SizedBox(height: 4),
        Text("${_teacherClasses.length} classes scheduled today", style: _ts(13, 400, Colors.white70)),
      ]);

  Widget _adminHero() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text("College Overview", style: _ts(22, 800, Colors.white)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text("Live", style: _ts(11, 800, Colors.white)),
            ]),
          ),
        ]),
        const SizedBox(height: 4),
        Text("Attendance across all departments", style: _ts(13, 400, Colors.white70)),
      ]);

  Widget _statsStrip(List<(String, String, IconData, Color)> items) {
    final t = Theme.of(context);
    return Container(
      height: 92,
      decoration: _cardDeco(t, r: 22, shadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Row(children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) Container(width: 1, height: 44, color: t.dividerColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(items[i].$3, color: items[i].$4, size: 16),
                  const SizedBox(width: 5),
                  Flexible(child: Text(items[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(19, 800, _headingOf(t)))),
                ]),
                const SizedBox(height: 4),
                Text(items[i].$2, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: _ts(11, 500, t.hintColor, h: 1.2)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  // ======================= STUDENT VIEW =======================
  Widget _studentView() {
    const today = [("Data Structures", "09:00 AM", true), ("Operating Systems", "11:00 AM", true), ("DBMS", "02:00 PM", false)];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _scanCard(),
      const SizedBox(height: 26),
      _scanHistory(),
      _sectionTitle(context, "Subject-wise Attendance"),
      const SizedBox(height: 14),
      _groupedCard(context, _subjects.map(_subjectRow).toList()),
      const SizedBox(height: 26),
      _sectionTitle(context, "Today's Status"),
      const SizedBox(height: 14),
      _groupedCard(context, today.map((e) => _statusRow(e.$1, e.$2, e.$3)).toList()),
    ]);
  }

  Widget _scanCard() {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(t, r: 22, shadow: [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Column(children: [
        Row(children: [
          _iconBox(Icons.qr_code_scanner_rounded, _iconOf(t), size: 54, iconSize: 28, r: 18, bg: _tintOf(t)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Mark attendance", style: _ts(16, 800, _headingOf(t))),
              const SizedBox(height: 3),
              Text("Scan the QR code shown by your teacher", style: _ts(12.5, 400, t.hintColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            label: const Text("Scan QR", style: TextStyle(fontWeight: FontWeight.w700)),
            style: _btn(),
          ),
        ),
      ]),
    );
  }

  Widget _scanHistory() {
    final user = _auth.getCurrentUser();
    if (user == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(context, "Marked via QR"),
      const SizedBox(height: 14),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('attendance_records').where('studentId', isEqualTo: user.id).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return _emptyNote(context, Icons.cloud_off_outlined, "Could not load your scans. Check your connection.");
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
          final docs = snap.data!.docs.toList();
          if (docs.isEmpty) return _emptyNote(context, Icons.qr_code_2_rounded, "No scans yet. Scan your teacher's QR to mark your first class.");
          docs.sort((a, b) => _markedAtOf(b.data()).compareTo(_markedAtOf(a.data())));
          return _groupedCard(context, docs.take(5).map((d) {
            final data = d.data(), when = _markedAtOf(data);
            final late = (data['status'] ?? 'present') == 'late';
            final c = late ? Colors.orange : Colors.green;
            return _rowTile(context, Icons.qr_code_2_rounded, c, (data['subjectName'] ?? data['subject'] ?? 'Class').toString(),
                "${_formatDate(when)} • ${_formatTime(when)}", _pill(late ? "Late" : "Present", c), big: true);
          }).toList());
        },
      ),
      const SizedBox(height: 26),
    ]);
  }

  Widget _subjectRow((String, String, int, int, int, String, Color) s) {
    final t = Theme.of(context);
    final (name, code, pct, total, present, faculty, base) = s;
    final st = pct < 75 ? Colors.red : (pct < 85 ? Colors.orange : Colors.green);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _iconBox(Icons.book_outlined, base),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(15, 700, _headingOf(t))),
              const SizedBox(height: 2),
              Text("$code • $faculty", style: _ts(12, 400, t.hintColor)),
            ]),
          ),
          Text("$pct%", style: _ts(17, 800, st)),
        ]),
        const SizedBox(height: 12),
        _bar(pct / 100, st),
        const SizedBox(height: 8),
        Text("$present of $total classes attended", style: _ts(11.5, 400, t.hintColor)),
      ]),
    );
  }

  Widget _statusRow(String sub, String time, bool present) {
    final t = Theme.of(context);
    final c = present ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        SizedBox(width: 74, child: Text(time, style: _ts(12, 700, t.hintColor))),
        Expanded(child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(14, 600, t.colorScheme.onSurface))),
        const SizedBox(width: 8),
        _pill(present ? "Present" : "Absent", c, icon: present ? Icons.check_circle : Icons.cancel),
      ]),
    );
  }

  // ======================= TEACHER VIEW =======================
  Widget _teacherView() {
    const tools = [
      (Icons.qr_code_scanner_rounded, "QR", Colors.blue),
      (Icons.face_retouching_natural_rounded, "Face", Colors.purple),
      (Icons.location_on_rounded, "GPS", Colors.orange),
      (Icons.wifi_off_rounded, "Offline", Colors.green),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(context, "Today's Classes"),
      const SizedBox(height: 14),
      ..._teacherClasses.map(_teacherClassCard),
      const SizedBox(height: 14),
      _sectionTitle(context, "Future Ready Attendance"),
      const SizedBox(height: 14),
      Row(
        children: tools
            .map((e) => Expanded(child: _futureTool(e.$1, e.$2, e.$3, e.$2 == "QR" ? () => _snack("Tap 'Show QR' on a class card to start a scan session") : null)))
            .toList(),
      ),
    ]);
  }

  Widget _teacherClassCard(Map<String, dynamic> c) {
    final t = Theme.of(context);
    final total = c["total"] as int, present = c["present"] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(t),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _pill(c["time"], _iconOf(t), bg: _tintOf(t), fs: 11.5, r: 9),
          const SizedBox(width: 10),
          Expanded(child: Text(c["subject"], maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(16, 800, _headingOf(t)))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.meeting_room_outlined, size: 14, color: t.hintColor),
          const SizedBox(width: 5),
          Text("${c["year"]} • Room ${c["room"]}", style: _ts(12, 600, t.hintColor)),
        ]),
        const SizedBox(height: 14),
        _bar(total == 0 ? 0 : present / total, Colors.green, h: 6, bg: Colors.red.withOpacity(0.15)),
        const SizedBox(height: 12),
        Row(children: [
          _pill("${c["present"]} present", Colors.green, fs: 11.5, r: 8, h: 9),
          const SizedBox(width: 8),
          _pill("${c["absent"]} absent", Colors.red, fs: 11.5, r: 8, h: 9),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _startQrSession(c),
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text("Show QR", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(foregroundColor: _iconOf(t), side: BorderSide(color: _primary.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showMarkSheet(c),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text("Mark", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              style: _btn(pad: 11, r: 12),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _futureTool(IconData icon, String label, Color color, VoidCallback? onTap) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.18))),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: _ts(11.5, 600, Theme.of(context).colorScheme.onSurface)),
        ]),
      );

  // ======================= ADMIN VIEW =======================
  Widget _adminView() {
    final t = Theme.of(context);
    const quick = [
      ("Teachers", "45", Icons.school_outlined),
      ("Students", "1.2k", Icons.groups_outlined),
      ("Reports", "12", Icons.summarize_outlined),
      ("Export", "PDF", Icons.picture_as_pdf_outlined),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(context, "Department Analytics"),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        decoration: _cardDeco(t),
        child: Column(children: _deptStats.map(_deptBar).toList()),
      ),
      const SizedBox(height: 26),
      _sectionTitle(context, "Quick Actions"),
      const SizedBox(height: 14),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 76,
        children: quick.map((q) => _quickCard(q.$1, q.$2, q.$3)).toList(),
      ),
    ]);
  }

  Widget _deptBar((String, int, Color) d) {
    final t = Theme.of(context);
    final (name, pct, c) = d;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        SizedBox(width: 90, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(12, 700, _headingOf(t)))),
        const SizedBox(width: 10),
        Expanded(
          child: Stack(children: [
            Container(height: 10, decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct / 100,
              child: Container(height: 10, decoration: BoxDecoration(gradient: LinearGradient(colors: [c.withOpacity(0.7), c]), borderRadius: BorderRadius.circular(6))),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 40, child: Text("$pct%", textAlign: TextAlign.right, style: _ts(12, 800, c))),
      ]),
    );
  }

  Widget _quickCard(String title, String value, IconData icon) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _cardDeco(t, r: 18),
      child: Row(children: [
        _iconBox(icon, _iconOf(t), bg: _tintOf(t)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(18, 800, _headingOf(t))),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(11.5, 600, t.hintColor)),
          ]),
        ),
      ]),
    );
  }

  // ======================= QR FLOW =======================
  Future<void> _openScanner() async {
    final raw = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const _QrScanPage()));
    if (raw != null && mounted) await _markAttendanceFromQr(raw);
  }

  Future<void> _fail(IconData icon, Color color, String title, String msg) async {
    _hideLoading();
    await _showScanResult(icon, color, title, msg);
  }

  Future<Position?> _checkLocation(double lat, double lng) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await _fail(Icons.location_off_rounded, Colors.red, "Location Services Off", "Please enable GPS to mark attendance.");
        return null;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        await _fail(Icons.location_off_rounded, Colors.red, "Location Permission Denied", "Attendance requires location permission to verify you are inside the classroom.");
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
      if (d > _classroomRadiusMeters) {
        await _fail(Icons.location_off_rounded, Colors.red, "Outside Classroom!",
            "You are ${d.round()} meters away from the class. You must be within ${_classroomRadiusMeters.round()} meters to mark attendance.");
        return null;
      }
      return pos;
    } catch (_) {
      await _fail(Icons.cloud_off_outlined, Colors.red, "Location Error", "Could not verify your location. Please ensure GPS is working.");
      return null;
    }
  }

  Future<void> _markAttendanceFromQr(String raw) async {
    final user = _auth.getCurrentUser();
    final working = raw.trim();
    final fromQr = working.startsWith(_qrPrefix);
    final parts = fromQr ? working.substring(_qrPrefix.length).split(':') : [working];
    final sessionId = parts[0].trim().toUpperCase();
    final token = parts.length > 1 ? parts[1].trim() : null;

    if (user == null) {
      await _showScanResult(Icons.lock_outline_rounded, Colors.red, "Please log in again", "We could not find your account.");
      return;
    }
    if (sessionId.isEmpty || sessionId.contains('/')) {
      await _showScanResult(Icons.qr_code_2_rounded, Colors.red, "Invalid QR code", "This is not an attendance QR. Ask your teacher to show the class QR.");
      return;
    }

    _showLoading();
    final doc = await _db.collection('attendance_sessions').doc(sessionId).get();
    if (!doc.exists) return _fail(Icons.qr_code_2_rounded, Colors.red, "QR not recognised", "We could not find this class session. Please try scanning again.");
    final session = doc.data() ?? {};

    // Dynamic token check (blocks screenshots / shared QR)
    if (fromQr && (session['securityToken'] == null || session['securityToken'] != token)) {
      return _fail(Icons.gpp_bad_outlined, Colors.red, "QR Expired or Copied!",
          "This QR code is old or a screenshot. The teacher's QR refreshes every 15 seconds. Please scan the live screen.");
    }

    // Status + expiry
    final exp = (session['expiresAt'] as Timestamp?)?.toDate();
    if (!_sessionIsActive(session) || (exp != null && DateTime.now().isAfter(exp))) {
      return _fail(Icons.timer_off_outlined, Colors.orange, "Session has ended", "This QR is no longer valid. Ask your teacher to start a new one.");
    }

    // Geofence
    final lat = (session['classroomLat'] as num?)?.toDouble(), lng = (session['classroomLng'] as num?)?.toDouble();
    Position? pos;
    if (lat != null && lng != null) {
      pos = await _checkLocation(lat, lng);
      if (pos == null) return;
    }

    // Save (transaction prevents duplicates)
    String status;
    try {
      final ref = _db.collection('attendance_records').doc('${sessionId}_${user.id}');
      status = await _db.runTransaction<String>((tx) async {
        if ((await tx.get(ref)).exists) return "already";
        final classDate = (session['classDate'] ?? _dateKey(DateTime.now())).toString();
        final start = _parseHHmm(session['classStartTime'] as String?, classDate);
        final end = _parseHHmm(session['classEndTime'] as String?, classDate);
        tx.set(
          ref,
          _record({...session, 'sessionId': sessionId, 'classDate': classDate}, user.id, user.fullName, user.collegeId, _computeStatus(start),
              fromQr ? 'qr' : 'manual', _verif(qr: fromQr, student: true, time: _isTimeVerified(start, end), loc: pos != null, acc: pos?.accuracy, gps: true),
              {'latitude': pos?.latitude, 'longitude': pos?.longitude, 'accuracy': pos?.accuracy, 'capturedAt': FieldValue.serverTimestamp()}),
        );
        return "ok";
      });
    } catch (e) {
      debugPrint("Attendance save error: $e");
      status = "error";
    }

    _hideLoading();
    if (!mounted) return;
    final classLine = "${session['subjectName'] ?? 'Class'} • ${session['roomName'] ?? ''}";
    if (status == "ok") {
      await _showScanResult(Icons.check_circle_rounded, Colors.green, "Attendance marked", "$classLine\nSaved at ${_formatTime(DateTime.now())}.");
    } else if (status == "already") {
      await _showScanResult(Icons.info_rounded, _primary, "Already marked", "Your attendance for this class is already saved.");
    } else {
      await _showScanResult(Icons.cloud_off_outlined, Colors.red, "Could not save", "Check your internet connection and try again.");
    }
  }

  Future<void> _startQrSession(Map<String, dynamic> c) async {
    final user = _auth.getCurrentUser();
    if (user == null) {
      _snack("Please log in again");
      return;
    }
    _showLoading();
    String? id, token;
    try {
      var code = _randomCode();
      for (int i = 0; i < 5 && (await _db.collection('attendance_sessions').doc(code).get()).exists; i++) {
        code = _randomCode();
      }
      final t = _randomToken();
      await _db.collection('attendance_sessions').doc(code).set(_sessionData(c, user, code, DateTime.now(), token: t));
      id = code;
      token = t;
    } catch (e) {
      debugPrint("Start session error: $e");
    }
    _hideLoading();
    if (!mounted) return;
    if (id == null || token == null) {
      _snack("Could not start the session. Check your internet connection.");
      return;
    }
    _showSheet((_) => _DynamicQrSheet(sessionId: id!, initialToken: token!, classData: c));
  }

  Future<void> _showScanResult(IconData icon, Color color, String title, String message) => showDialog(
        context: context,
        builder: (ctx) {
          final t = Theme.of(ctx);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _iconBox(icon, color, size: 64, iconSize: 34, r: 20),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center, style: _ts(18, 800, _headingOf(t))),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: _ts(13.5, 400, t.hintColor, h: 1.4)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: _btn(pad: 13, r: 14), child: const Text("Done", style: TextStyle(fontWeight: FontWeight.w700))),
                ),
              ]),
            ),
          );
        },
      );

  void _showLoading() => showDialog(
      context: context, barrierDismissible: false, builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())));

  void _hideLoading() {
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // ======================= MANUAL MARK SHEET =======================
  void _showMarkSheet(Map<String, dynamic> classData) {
    final marks = List.filled(10, "P");
    _showSheet((_) => StatefulBuilder(builder: (ctx, setS) {
          final t = Theme.of(ctx);
          int n(String m) => marks.where((x) => x == m).length;
          return _sheetFrame(
            ctx,
            h: 0.85,
            title: "Mark Attendance",
            sub: "${classData["subject"]} - ${classData["year"]}",
            extra: Row(children: [
              for (final e in [("Present", "P"), ("Absent", "A"), ("Leave", "L")]) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text("${e.$1} ${n(e.$2)}", style: _ts(12, 700, Colors.white)),
                ),
              ],
            ]),
            body: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: marks.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: _cardDeco(t, r: 16),
                child: Row(children: [
                  _iconBox(Icons.person_outline, _iconOf(t), size: 38, iconSize: 20, r: 12, bg: _tintOf(t)),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Student ${i + 1}", style: _ts(14, 600, t.colorScheme.onSurface))),
                  for (final e in [("P", Colors.green), ("A", Colors.red), ("L", Colors.orange)])
                    _markButton(e.$1, e.$2, marks[i] == e.$1, () => setS(() => marks[i] = e.$1)),
                ]),
              ),
            ),
            footer: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveManualAttendance(classData, marks);
              },
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text("Save attendance", style: TextStyle(fontWeight: FontWeight.w700)),
              style: _btn(pad: 15),
            ),
          );
        }));
  }

  Widget _markButton(String label, Color color, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Material(
          color: selected ? color : color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(width: 34, height: 34, alignment: Alignment.center, child: Text(label, style: _ts(14, 900, selected ? Colors.white : color))),
          ),
        ),
      );

  Future<void> _saveManualAttendance(Map<String, dynamic> c, List<String> marks) async {
    final user = _auth.getCurrentUser();
    if (user == null) {
      _snack("Please log in again");
      return;
    }
    _showLoading();
    try {
      final now = DateTime.now();
      final sid = "MAN-${user.id.substring(0, 5)}-${c['subjectId']}-${c['divisionId']}-${c['semester']}-${c['academicYear']}-${_dateKey(now)}"
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
      final session = _sessionData(c, user, sid, now);
      await _db.collection('attendance_sessions').doc(sid).set(session, SetOptions(merge: true));

      final batch = _db.batch();
      for (int i = 0; i < marks.length; i++) {
        final studentId = "DUMMY_${i + 1}";
        final status = marks[i] == "P" ? "present" : (marks[i] == "A" ? "absent" : "excused");
        batch.set(_db.collection('attendance_records').doc("${sid}_$studentId"),
            _record(session, studentId, "Student ${i + 1}", "N/A", status, 'manual', _verif(), null), SetOptions(merge: true));
      }
      await batch.commit();
      _hideLoading();
      if (mounted) _snack("Manual attendance saved successfully.");
    } catch (e) {
      _hideLoading();
      debugPrint("Manual save error: $e");
      if (mounted) _snack("Failed to save manual attendance. Check connection.");
    }
  }
}

// ======================= LIVE SCANS LIST =======================
class _LiveScans extends StatelessWidget {
  final String sessionId;
  const _LiveScans(this.sessionId);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('attendance_records').where('sessionId', isEqualTo: sessionId).snapshots(),
      builder: (_, snap) {
        final docs = (snap.data?.docs ?? []).toList()..sort((a, b) => _markedAtOf(b.data()).compareTo(_markedAtOf(a.data())));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text("Scanned students", style: _ts(16, 800, _headingOf(t)))),
            _pill("${docs.length}", _iconOf(t), bg: _tintOf(t), fs: 12.5, v: 4),
          ]),
          const SizedBox(height: 12),
          if (snap.hasError)
            _emptyNote(context, Icons.cloud_off_outlined, "Could not load scans. Check your connection.")
          else if (docs.isEmpty)
            _emptyNote(context, Icons.hourglass_empty_rounded, "Waiting for students to scan...")
          else
            _groupedCard(context, docs.map((d) {
              final data = d.data();
              return _rowTile(context, Icons.check_rounded, Colors.green, (data['studentName'] ?? 'Student').toString(),
                  (data['collegeId'] ?? '').toString(), Text(_formatTime(_markedAtOf(data)), style: _ts(11.5, 600, t.hintColor)));
            }).toList()),
        ]);
      },
    );
  }
}

// ======================= DYNAMIC QR SHEET (rotates every 15s) =======================
class _DynamicQrSheet extends StatefulWidget {
  final String sessionId, initialToken;
  final Map<String, dynamic> classData;
  const _DynamicQrSheet({required this.sessionId, required this.initialToken, required this.classData});

  @override
  State<_DynamicQrSheet> createState() => _DynamicQrSheetState();
}

class _DynamicQrSheetState extends State<_DynamicQrSheet> {
  late String _token = widget.initialToken;
  late final Timer _timer;
  int _left = 15;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_left == 0) {
          _left = 15;
          _rotate();
        } else {
          _left--;
        }
      });
    });
  }

  Future<void> _rotate() async {
    final newToken = _randomToken();
    try {
      await _db.collection('attendance_sessions').doc(widget.sessionId).update({
        'securityToken': newToken,
        'qrVersion': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _token = newToken);
    } catch (e) {
      debugPrint("QR Rotation Error: $e");
    }
  }

  Future<void> _endSession() async {
    try {
      await _db.collection('attendance_sessions').doc(widget.sessionId).update({
        'status': 'closed', 'active': false, 'closedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("End session error: $e");
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final warn = _left <= 5;
    final c = warn ? Colors.red : _iconOf(t);
    return _sheetFrame(
      context,
      h: 0.92,
      title: "Live Attendance QR",
      sub: "${widget.classData["subject"]} - ${widget.classData["year"]}",
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Stack(alignment: Alignment.center, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: QrImageView(key: ValueKey(_token), data: "$_qrPrefix${widget.sessionId}:$_token", version: QrVersions.auto, size: 210, backgroundColor: Colors.white),
                ),
              ),
              if (_left <= 3)
                Container(
                  width: 242,
                  height: 242,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(24)),
                  child: const Icon(Icons.sync_rounded, color: Colors.white, size: 48),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          Center(
            child: _pill("QR refreshes in $_left seconds", c, bg: warn ? Colors.red.withOpacity(0.15) : _tintOf(t), fs: 12.5, r: 12, h: 12, v: 6, icon: warn ? Icons.timer_off_rounded : Icons.timer_outlined),
          ),
          const SizedBox(height: 24),
          _LiveScans(widget.sessionId),
        ]),
      ),
      footer: OutlinedButton.icon(
        onPressed: _endSession,
        icon: const Icon(Icons.stop_circle_outlined, size: 20, color: Colors.red),
        label: const Text("End session", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}

// ======================= CAMERA SCAN PAGE =======================
class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, facing: CameraFacing.back, formats: const [BarcodeFormat.qrCode]);
  final _code = TextEditingController();
  bool _handled = false, _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    _code.dispose();
    super.dispose();
  }

  void _finish(String v) {
    _handled = true;
    Navigator.pop(context, v);
  }

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    for (final b in cap.barcodes) {
      final v = b.rawValue;
      if (v != null && v.trim().isNotEmpty) {
        HapticFeedback.mediumImpact();
        return _finish(v);
      }
    }
  }

  Future<void> _enterManually() async {
    _code.clear();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Enter code", style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: _code,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: "e.g. K7P2QX", border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, _code.text), style: _btn(pad: 12, r: 12), child: const Text("Use code")),
        ],
      ),
    );
    if (code != null && code.trim().isNotEmpty && mounted) _finish(code.trim());
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap, String tip) => Tooltip(
        message: tip,
        child: Material(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 22))),
        ),
      );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (_, __) => Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.no_photography_outlined, color: Colors.white54, size: 48),
                    const SizedBox(height: 14),
                    Text("Camera is not available.\nAllow camera permission in settings, or enter the code manually.", textAlign: TextAlign.center, style: _ts(14, 400, Colors.white70, h: 1.4)),
                  ]),
                ),
              ),
            ),
            Center(
              child: IgnorePointer(
                child: Container(width: 250, height: 250, decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white, width: 3))),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  _roundBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context), "Back"),
                  Expanded(child: Text("Scan attendance QR", textAlign: TextAlign.center, style: _ts(17, 700, Colors.white))),
                  _roundBtn(_torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, () {
                    _controller.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  }, "Torch"),
                ]),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text("Point the camera at the QR code shown by your teacher", textAlign: TextAlign.center, style: _ts(13.5, 400, Colors.white70)),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: _enterManually,
                      icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white, size: 20),
                      label: const Text("Enter code manually", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.18), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
}

// ======================= HEADER BACKGROUND PAINTER =======================
class _HeaderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += 28) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);

    final ring = Paint()..color = Colors.white.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final c = Offset(size.width - 30, size.height - 40);
    for (final r in [36.0, 64.0, 92.0]) canvas.drawCircle(c, r, ring);

    final dot = Paint()..color = Colors.white.withOpacity(0.45);
    for (final o in [Offset(c.dx - 36, c.dy), Offset(c.dx, c.dy - 64), Offset(c.dx - 92, c.dy)]) canvas.drawCircle(o, 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}