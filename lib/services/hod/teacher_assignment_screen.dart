import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../academic_class_model.dart';
import '../../academic_year_model.dart';
import '../../subject_assignment_model.dart';
import '../../subject_model.dart';
import '../../user_model.dart';
import '../../user_role.dart';
import '../academic_class_service.dart';
import '../academic_year_service.dart';
import '../auth_service.dart';
import '../subject_assignment_service.dart';
import '../subject_service.dart';

class TeacherAssignmentScreen extends StatefulWidget {
  const TeacherAssignmentScreen({super.key});

  @override
  State<TeacherAssignmentScreen> createState() => _TeacherAssignmentScreenState();
}

class _TeacherAssignmentScreenState extends State<TeacherAssignmentScreen> {
  final _auth = AuthService();
  final _classService = AcademicClassService();
  final _yearService = AcademicYearService();
  final _subjectService = SubjectService();
  final _assignmentService = SubjectAssignmentService();

  UserModel? _currentUser;
  List<UserModel> _teachers = [];
  List<SubjectModel> _subjects = [];
  List<AcademicClassModel> _classes = [];
  List<AcademicYearModel> _years = [];
  List<SubjectAssignmentModel> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _norm(String s) => s.trim().toLowerCase();

  T? _byId<T>(Iterable<T> list, String? id, String Function(T) getId) =>
      list.where((e) => getId(e) == id).firstOrNull;

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final user = _auth.getCurrentUser();
      if (user == null) throw Exception('Logged-in user information not found.');

      final dept = _norm(user.department);
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['teacher', 'hod'])
          .where('isActive', isEqualTo: true)
          .get();

      final teachers = users.docs
          .map((d) => _userFromFirestore(d.id, d.data()))
          .where((u) => _norm(u.department) == dept)
          .toList();
      final subjects = (await _subjectService.getActiveSubjects())
          .where((s) => _norm(s.department) == dept)
          .toList();
      final classes = (await _classService.getClassesByDepartment(user.department))
          .where((c) => c.isActive)
          .toList();
      final years = await _yearService.getActiveAcademicYears();
      final assignments = await _assignmentService.getDepartmentAssignments(user.department);

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _teachers = teachers;
        _subjects = subjects;
        _classes = classes;
        _years = years;
        _assignments = assignments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Failed to load data: $e', error: true);
    }
  }

  UserModel _userFromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    String str(String key, [String def = '']) => data[key]?.toString() ?? def;
    DateTime? optDate(String key) => data[key] == null ? null : parseDate(data[key]);

    return UserModel(
      id: id,
      collegeId: str('collegeId'),
      fullName: str('fullName', 'Unknown User'),
      email: str('email'),
      password: '',
      role: _parseRole(data['role']?.toString()),
      department: str('department'),
      designation: str('designation', 'Teacher'),
      semester: (data['semester'] as num?)?.toInt(),
      division: data['division']?.toString(),
      rollNumber: data['rollNumber']?.toString(),
      phoneNumber: str('phoneNumber'),
      gender: str('gender'),
      dateOfBirth: optDate('dateOfBirth'),
      profileImageUrl: data['profileImageUrl']?.toString(),
      address: str('address'),
      isActive: data['isActive'] as bool? ?? true,
      lastLogin: optDate('lastLogin'),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  UserRole _parseRole(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'hod':
        return UserRole.hod;
      case 'principal':
        return UserRole.principal;
      default: // teacher / faculty / unknown
        return UserRole.teacher;
    }
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
          items: items,
          onChanged: onChanged,
        ),
      );

  DropdownMenuItem<T> _item<T>(T value, String text) =>
      DropdownMenuItem(value: value, child: Text(text, overflow: TextOverflow.ellipsis));

  Future<void> _openAssignmentDialog({SubjectAssignmentModel? existing}) async {
    if (_currentUser == null) return;

    String? teacherId = existing?.teacherId;
    String? yearId = existing?.academicYearId;
    String? classId = existing?.classId;
    String? division = existing?.division;
    int? semester = existing?.semester;
    String? subjectId = existing?.subjectId;
    String type = existing?.assignmentType.isNotEmpty == true
        ? existing!.assignmentType
        : 'regular';

    if (yearId == null && _years.isNotEmpty) {
      yearId = (_years.where((y) => y.isCurrent).firstOrNull ?? _years.first).id;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedClass = _byId(_classes, classId, (c) => c.id);
          final divisions = selectedClass?.divisions ?? <String>[];
          final semesters = selectedClass?.semesters ?? <int>[];

          if (!divisions.contains(division)) division = null;
          if (!semesters.contains(semester)) {
            semester = null;
            subjectId = null;
          }

          final availableSubjects =
              _subjects.where((s) => semester == null || s.semester == semester).toList();
          if (!availableSubjects.any((s) => s.id == subjectId)) subjectId = null;

          return AlertDialog(
            title: Text(existing == null ? 'Assign Subject' : 'Edit Assignment'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dropdown<String>(
                      label: 'Teacher / HOD',
                      icon: Icons.person_outline,
                      value: teacherId,
                      items: _teachers
                          .map((t) => _item(t.id, '${t.fullName} (${t.designation})'))
                          .toList(),
                      onChanged: (v) => setDialogState(() => teacherId = v),
                    ),
                    _dropdown<String>(
                      label: 'Academic Year',
                      icon: Icons.calendar_today_outlined,
                      value: yearId,
                      items: _years
                          .map((y) => _item(y.id, y.isCurrent ? '${y.name} (Current)' : y.name))
                          .toList(),
                      onChanged: _years.isEmpty ? null : (v) => setDialogState(() => yearId = v),
                    ),
                    _dropdown<String>(
                      label: 'Class / Program',
                      icon: Icons.school_outlined,
                      value: classId,
                      items: _classes
                          .map((c) => _item(c.id, '${c.program} • ${c.yearName}'))
                          .toList(),
                      onChanged: _classes.isEmpty
                          ? null
                          : (v) => setDialogState(() {
                                classId = v;
                                division = null;
                                semester = null;
                                subjectId = null;
                              }),
                    ),
                    _dropdown<String>(
                      label: 'Division',
                      icon: Icons.groups_outlined,
                      value: division,
                      items: divisions.map((d) => _item(d, 'Division $d')).toList(),
                      onChanged:
                          selectedClass == null ? null : (v) => setDialogState(() => division = v),
                    ),
                    _dropdown<int>(
                      label: 'Semester',
                      icon: Icons.format_list_numbered,
                      value: semester,
                      items: semesters.map((s) => _item(s, 'Semester $s')).toList(),
                      onChanged: selectedClass == null
                          ? null
                          : (v) => setDialogState(() {
                                semester = v;
                                subjectId = null;
                              }),
                    ),
                    _dropdown<String>(
                      label: 'Subject',
                      icon: Icons.menu_book_outlined,
                      value: subjectId,
                      items: availableSubjects
                          .map((s) => _item(s.id, '${s.code} • ${s.name}'))
                          .toList(),
                      onChanged:
                          semester == null ? null : (v) => setDialogState(() => subjectId = v),
                    ),
                    _dropdown<String>(
                      label: 'Assignment Type',
                      icon: Icons.category_outlined,
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'regular', child: Text('Regular')),
                        DropdownMenuItem(value: 'lab', child: Text('Lab')),
                        DropdownMenuItem(value: 'elective', child: Text('Elective')),
                        DropdownMenuItem(value: 'substitute', child: Text('Substitute')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => type = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => _saveAssignment(
                  dialogContext,
                  existing: existing,
                  teacherId: teacherId,
                  yearId: yearId,
                  classId: classId,
                  division: division,
                  semester: semester,
                  subjectId: subjectId,
                  type: type,
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(existing == null ? 'Assign' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveAssignment(
    BuildContext dialogContext, {
    required SubjectAssignmentModel? existing,
    required String? teacherId,
    required String? yearId,
    required String? classId,
    required String? division,
    required int? semester,
    required String? subjectId,
    required String type,
  }) async {
    if (teacherId == null || yearId == null || classId == null ||
        division == null || semester == null || subjectId == null) {
      _snack('Select Teacher, Academic Year, Class, Division, Semester and Subject.',
          error: true);
      return;
    }

    final teacher = _byId(_teachers, teacherId, (e) => e.id);
    final year = _byId(_years, yearId, (e) => e.id);
    final cls = _byId(_classes, classId, (e) => e.id);
    final subject = _byId(_subjects, subjectId, (e) => e.id);
    final user = _currentUser;

    if (teacher == null || year == null || cls == null || subject == null || user == null) {
      _snack('Selected data is unavailable. Refresh and try again.', error: true);
      return;
    }

    final duplicate = _assignments.any((a) =>
        a.id != existing?.id &&
        a.isActive &&
        a.teacherId == teacher.id &&
        a.subjectId == subject.id &&
        a.classId == cls.id &&
        a.division == division &&
        a.semester == semester &&
        a.academicYearId == year.id);

    if (duplicate) {
      _snack('This subject is already assigned to this teacher for this class, division, semester and academic year.',
          error: true);
      return;
    }

    try {
      final now = DateTime.now();
      final assignment = SubjectAssignmentModel(
        id: existing?.id ?? '',
        teacherId: teacher.id,
        teacherName: teacher.fullName,
        subjectId: subject.id,
        subjectName: subject.name,
        subjectCode: subject.code,
        department: user.department,
        classId: cls.id,
        className: cls.yearName,
        program: cls.program,
        division: division,
        semester: semester,
        academicYearId: year.id,
        academicYear: year.name,
        assignmentType: type,
        startDate: existing?.startDate ?? now,
        endDate: existing?.endDate,
        assignedBy: user.id,
        assignedByName: user.fullName,
        isActive: true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      existing == null
          ? await _assignmentService.createAssignment(assignment)
          : await _assignmentService.updateAssignment(assignment);

      if (!mounted) return;
      Navigator.pop(dialogContext);
      await _loadData();
      _snack(existing == null
          ? 'Subject assigned successfully.'
          : 'Assignment updated successfully.');
    } catch (e) {
      _snack('Failed to save assignment: $e', error: true);
    }
  }

  /// Runs [action], reloads data and shows [success]; shows [failure] on error.
  Future<void> _run(Future<void> Function() action, String success, String failure) async {
    try {
      await action();
      await _loadData();
      _snack(success);
    } catch (e) {
      _snack('$failure: $e', error: true);
    }
  }

  Future<void> _toggleAssignment(SubjectAssignmentModel a) => _run(
        () => _assignmentService.setAssignmentStatus(a.id, !a.isActive),
        a.isActive ? 'Assignment deactivated.' : 'Assignment activated.',
        'Failed to update assignment',
      );

  Future<void> _deleteAssignment(SubjectAssignmentModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Delete ${a.subjectName} assignment for ${a.teacherName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _assignmentService.deleteAssignment(a.id), 'Assignment deleted.',
        'Failed to delete assignment');
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Colors.red.shade700 : null,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Assignment'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : () => _openAssignmentDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Assign Subject'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(onRefresh: _loadData, child: _buildAssignmentList()),
      );

  Widget _buildAssignmentList() {
    if (_assignments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .25),
          const Icon(Icons.assignment_outlined, size: 64),
          const SizedBox(height: 16),
          const Center(
            child: Text('No subject assignments found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Tap "Assign Subject" to create one.')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (context, i) => _assignmentCard(_assignments[i]),
    );
  }

  Widget _assignmentCard(SubjectAssignmentModel item) {
    final statusColor = item.isActive ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.subjectName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(item.subjectCode, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _openAssignmentDialog(existing: item);
                    if (v == 'toggle') _toggleAssignment(item);
                    if (v == 'delete') _deleteAssignment(item);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                        value: 'toggle', child: Text(item.isActive ? 'Deactivate' : 'Activate')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow(Icons.person_outline, 'Teacher', item.teacherName),
            _infoRow(Icons.school_outlined, 'Class',
                item.program.isNotEmpty ? '${item.program} • ${item.className}' : item.className),
            _infoRow(Icons.groups_outlined, 'Section',
                'Division ${item.division} • Semester ${item.semester}'),
            _infoRow(Icons.calendar_today_outlined, 'Academic Year', item.academicYear),
            _infoRow(Icons.category_outlined, 'Type', _formatType(item.assignmentType)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text('Assigned by ${item.assignedByName}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  String _formatType(String type) =>
      type.isEmpty ? 'Regular' : '${type[0].toUpperCase()}${type.substring(1)}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}