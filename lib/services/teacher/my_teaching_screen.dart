import 'package:flutter/material.dart';

import '../../subject_assignment_model.dart';
import '../../services/auth_service.dart';
import '../../services/subject_assignment_service.dart';
import '../../teaching_context.dart';
import '../../user_model.dart';
import '../../user_role.dart';
import 'class_environment_screen.dart';

// Theme colors
const _bg = Color(0xFF0B1120);
const _card = Color(0xFF111827);
const _border = Color(0xFF1E293B);
const _line = Color(0xFF334155);
const _blue = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _muted = Color(0xFF94A3B8);
const _dim = Color(0xFF64748B);

class MyTeachingScreen extends StatefulWidget {
  const MyTeachingScreen({super.key, this.onContextSelected});

  final ValueChanged<TeachingContext>? onContextSelected;

  @override
  State<MyTeachingScreen> createState() => _MyTeachingScreenState();
}

class _MyTeachingScreenState extends State<MyTeachingScreen> {
  final _authService = AuthService();
  final _assignmentService = SubjectAssignmentService();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectAssignmentModel> _assignments = [];

  String? _yearId;
  String? _classId;
  String? _division;
  int? _semester;

  @override
  void initState() {
    super.initState();
    _loadTeachingAssignments();
  }

  Future<void> _loadTeachingAssignments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('User session not found.');
      if (user.role != UserRole.teacher && user.role != UserRole.hod) {
        throw Exception('My Teaching is available only for Teacher and HOD accounts.');
      }

      final assignments = await _assignmentService.getTeacherAssignments(user.id);
      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _assignments = assignments.where((a) => a.isActive).toList();
        _yearId = _classId = _division = _semester = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ---------------- FILTER DATA ----------------

  String _classLabel(SubjectAssignmentModel a) {
    if (a.className.trim().isNotEmpty) return a.className;
    if (a.program.trim().isNotEmpty) return a.program;
    return 'Class';
  }

  List<SubjectAssignmentModel> get _yearAssignments =>
      _yearId == null ? _assignments : _assignments.where((a) => a.academicYearId == _yearId).toList();

  List<SubjectAssignmentModel> get _classAssignments =>
      _classId == null ? _yearAssignments : _yearAssignments.where((a) => a.classId == _classId).toList();

  List<SubjectAssignmentModel> get _divisionAssignments =>
      _division == null ? _classAssignments : _classAssignments.where((a) => a.division == _division).toList();

  List<_FilterItem> get _yearItems {
    final unique = <String, _FilterItem>{
      for (final a in _assignments)
        if (a.academicYearId.trim().isNotEmpty && a.academicYear.trim().isNotEmpty)
          a.academicYearId: _FilterItem(a.academicYearId, a.academicYear),
    };
    return unique.values.toList()..sort((a, b) => b.label.compareTo(a.label));
  }

  List<_FilterItem> get _classItems {
    final unique = <String, _FilterItem>{
      for (final a in _yearAssignments)
        if (a.classId.trim().isNotEmpty) a.classId: _FilterItem(a.classId, _classLabel(a)),
    };
    return unique.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  List<_FilterItem> get _divisionItems {
    final unique = <String, _FilterItem>{
      for (final a in _classAssignments)
        if (a.division.trim().isNotEmpty)
          a.division.trim(): _FilterItem(a.division.trim(), 'Division ${a.division.trim()}'),
    };
    return unique.values.toList()..sort((a, b) => a.label.compareTo(b.label));
  }

  List<_FilterItem> get _semesterItems {
    final semesters = {
      for (final a in _divisionAssignments)
        if (a.semester > 0) a.semester,
    }.toList()
      ..sort();
    return semesters.map((s) => _FilterItem('$s', 'Semester $s')).toList();
  }

  List<SubjectAssignmentModel> get _filteredAssignments {
    final result = _semester == null
        ? [..._divisionAssignments]
        : _divisionAssignments.where((a) => a.semester == _semester).toList();
    return result
      ..sort((a, b) => a.subjectName.toLowerCase().compareTo(b.subjectName.toLowerCase()));
  }

  // ---------------- OPEN TEACHING CONTEXT ----------------

  void _selectAssignment(SubjectAssignmentModel a) {
    final user = _currentUser;
    if (user == null) return;

    final teachingContext = TeachingContext(
      teacherId: user.id,
      teacherName: user.fullName,
      assignmentId: a.id,
      department: a.department,
      program: a.program,
      academicYearId: a.academicYearId,
      academicYear: a.academicYear,
      classId: a.classId,
      className: a.className,
      division: a.division,
      semester: a.semester,
      subjectId: a.subjectId,
      subjectName: a.subjectName,
      subjectCode: a.subjectCode,
      assignmentType: a.assignmentType,
    );

    teachingContext.debugPrintContext();

    // Parent/dashboard can handle the selected context; otherwise open Class Environment.
    if (widget.onContextSelected != null) {
      widget.onContextSelected!(teachingContext);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClassEnvironmentScreen(teachingContext: teachingContext)),
    );
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          title: const Text('My Teaching', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : _loadTeachingAssignments,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return _centerState(
        leading: const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFFEF4444)),
        title: 'Unable to Load Teaching',
        titleSize: 19,
        message: _errorMessage ?? 'Something went wrong.',
        messageColor: _muted,
        button: ElevatedButton.icon(
          onPressed: _loadTeachingAssignments,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
        ),
      );
    }

    if (_assignments.isEmpty) {
      return _centerState(
        leading: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.assignment_outlined, size: 38, color: Color(0xFF475569)),
        ),
        title: 'No Teaching Assignments',
        titleSize: 20,
        message: 'You currently have no active subjects assigned to you.',
        messageColor: _dim,
        button: OutlinedButton.icon(
          onPressed: _loadTeachingAssignments,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      );
    }

    const gap = SizedBox(height: 14);
    return RefreshIndicator(
      onRefresh: _loadTeachingAssignments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _selector(
            label: 'Academic Year',
            hint: 'Select academic year',
            items: _yearItems,
            selected: _yearId,
            onChanged: (id) => setState(() {
              _yearId = id;
              _classId = _division = _semester = null;
            }),
          ),
          gap,
          _selector(
            label: 'Class / Year',
            hint: _yearId == null ? 'Select academic year first' : 'Select class / year',
            items: _classItems,
            selected: _classId,
            enabled: _yearId != null,
            onChanged: (id) => setState(() {
              _classId = id;
              _division = _semester = null;
            }),
          ),
          gap,
          _selector(
            label: 'Division',
            hint: _classId == null ? 'Select class first' : 'Select division',
            items: _divisionItems,
            selected: _division,
            enabled: _classId != null,
            onChanged: (id) => setState(() {
              _division = id;
              _semester = null;
            }),
          ),
          gap,
          _selector(
            label: 'Semester',
            hint: _division == null ? 'Select division first' : 'Select semester',
            items: _semesterItems,
            selected: _semester?.toString(),
            enabled: _division != null,
            onChanged: (id) => setState(() => _semester = id == null ? null : int.tryParse(id)),
          ),
          const SizedBox(height: 24),
          _buildAssignmentTitle(),
          const SizedBox(height: 12),
          _buildAssignmentList(),
        ],
      ),
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF172554), _card]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school_rounded, color: _blueLight, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.fullName ?? 'Teacher',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser?.role == UserRole.hod
                        ? 'HOD • Teaching Assignments'
                        : 'Teacher • Teaching Assignments',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_assignments.length}',
                style: const TextStyle(color: Color(0xFF93C5FD), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

  /// Dropdown driven by an id; [selected] is shown only if it exists in [items].
  Widget _selector({
    required String label,
    required String hint,
    required List<_FilterItem> items,
    required String? selected,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          // `value` (not initialValue) so dependent filters reset on rebuild.
          value: items.any((i) => i.id == selected) ? selected : null,
          isExpanded: true,
          dropdownColor: _card,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _dim),
            filled: true,
            fillColor: enabled ? _card : const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: border(_line),
            enabledBorder: border(_line),
            focusedBorder: border(const Color(0xFF3B82F6), 1.2),
            disabledBorder: border(_border),
          ),
          items: enabled
              ? items
                  .map((i) => DropdownMenuItem(
                        value: i.id,
                        child: Text(i.label, overflow: TextOverflow.ellipsis),
                      ))
                  .toList()
              : null,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  Widget _buildAssignmentTitle() {
    final count = _filteredAssignments.length;
    return Row(
      children: [
        const Expanded(
          child: Text('Assigned Subjects',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        Text('$count subject${count == 1 ? '' : 's'}',
            style: const TextStyle(color: _dim, fontSize: 13)),
      ],
    );
  }

  Widget _buildAssignmentList() {
    final hint = switch ((_yearId, _classId, _division, _semester)) {
      (null, _, _, _) => (
          Icons.calendar_month_rounded,
          'Select Academic Year',
          'Choose an academic year to see your assigned classes and subjects.'
        ),
      (_, null, _, _) => (
          Icons.school_outlined,
          'Select Class / Year',
          'Choose a class or year from your assigned teaching workload.'
        ),
      (_, _, null, _) => (
          Icons.groups_rounded,
          'Select Division',
          'Choose the division you are assigned to teach.'
        ),
      (_, _, _, null) => (
          Icons.menu_book_rounded,
          'Select Semester',
          'Choose the semester to view assigned subjects.'
        ),
      _ => _filteredAssignments.isEmpty
          ? (
              Icons.search_off_rounded,
              'No Subjects Found',
              'No active subject assignment matches the selected teaching context.'
            )
          : null,
    };

    if (hint != null) {
      return _selectionHint(icon: hint.$1, title: hint.$2, message: hint.$3);
    }
    return Column(children: _filteredAssignments.map(_buildAssignmentCard).toList());
  }

  Widget _buildAssignmentCard(SubjectAssignmentModel a) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _selectAssignment(a),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: _blueLight),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          a.subjectCode.isEmpty ? 'Subject' : a.subjectCode,
                          style: const TextStyle(
                              color: _blueLight, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _infoChip(Icons.school_outlined, _classLabel(a)),
                            _infoChip(Icons.groups_outlined, 'Div ${a.division}'),
                            _infoChip(Icons.layers_outlined, 'Sem ${a.semester}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 17, color: _dim),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _infoChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _muted),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
      );

  Widget _selectionHint({
    required IconData icon,
    required String title,
    required String message,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 42, color: const Color(0xFF475569)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _dim, height: 1.45, fontSize: 13)),
          ],
        ),
      );

  /// Shared layout for the empty and error screens.
  Widget _centerState({
    required Widget leading,
    required String title,
    required double titleSize,
    required String message,
    required Color messageColor,
    required Widget button,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: messageColor, height: 1.45)),
              const SizedBox(height: 20),
              button,
            ],
          ),
        ),
      );
}

class _FilterItem {
  final String id;
  final String label;
  const _FilterItem(this.id, this.label);
}