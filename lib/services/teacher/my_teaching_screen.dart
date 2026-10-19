import 'package:flutter/material.dart';

import '../../subject_assignment_model.dart';
import '../../services/auth_service.dart';
import '../../services/subject_assignment_service.dart';
import '../../teaching_context.dart';
import '../../user_model.dart';
import '../../user_role.dart';
import 'class_environment_screen.dart';

class MyTeachingScreen extends StatefulWidget {
  const MyTeachingScreen({
    super.key,
    this.onContextSelected,
  });

  final ValueChanged<TeachingContext>? onContextSelected;

  @override
  State<MyTeachingScreen> createState() => _MyTeachingScreenState();
}

class _MyTeachingScreenState extends State<MyTeachingScreen> {
  final AuthService _authService = AuthService();

  final SubjectAssignmentService _assignmentService =
      SubjectAssignmentService();

  UserModel? _currentUser;

  bool _isLoading = true;
  String? _errorMessage;

  List<SubjectAssignmentModel> _assignments = [];

  String? _selectedAcademicYearId;
  String? _selectedClassId;
  String? _selectedDivision;
  int? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _loadTeachingAssignments();
  }

  // ============================================================
  // LOAD TEACHING ASSIGNMENTS
  // ============================================================

  Future<void> _loadTeachingAssignments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = _authService.getCurrentUser();

      if (user == null) {
        throw Exception('User session not found.');
      }

      if (user.role != UserRole.teacher &&
          user.role != UserRole.hod) {
        throw Exception(
          'My Teaching is available only for Teacher and HOD accounts.',
        );
      }

      final assignments =
          await _assignmentService.getTeacherAssignments(user.id);

      final activeAssignments = assignments
          .where((assignment) => assignment.isActive)
          .toList();

      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _assignments = activeAssignments;

        _selectedAcademicYearId = null;
        _selectedClassId = null;
        _selectedDivision = null;
        _selectedSemester = null;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // ACADEMIC YEAR DATA
  // ============================================================

  List<_FilterItem> get _academicYearItems {
    final unique = <String, _FilterItem>{};

    for (final assignment in _assignments) {
      if (assignment.academicYearId.trim().isEmpty) continue;
      if (assignment.academicYear.trim().isEmpty) continue;

      unique[assignment.academicYearId] = _FilterItem(
        id: assignment.academicYearId,
        label: assignment.academicYear,
      );
    }

    final items = unique.values.toList();

    items.sort(
      (a, b) => b.label.compareTo(a.label),
    );

    return items;
  }

  List<SubjectAssignmentModel> get _yearAssignments {
    if (_selectedAcademicYearId == null) {
      return _assignments;
    }

    return _assignments
        .where(
          (assignment) =>
              assignment.academicYearId ==
              _selectedAcademicYearId,
        )
        .toList();
  }

  // ============================================================
  // CLASS DATA
  // ============================================================

  List<_FilterItem> get _classItems {
    final unique = <String, _FilterItem>{};

    for (final assignment in _yearAssignments) {
      if (assignment.classId.trim().isEmpty) continue;

      String label = assignment.className.trim();

      if (label.isEmpty) {
        label = assignment.program.trim();
      }

      if (label.isEmpty) {
        label = 'Class';
      }

      unique[assignment.classId] = _FilterItem(
        id: assignment.classId,
        label: label,
      );
    }

    final items = unique.values.toList();

    items.sort(
      (a, b) => a.label.toLowerCase().compareTo(
            b.label.toLowerCase(),
          ),
    );

    return items;
  }

  List<SubjectAssignmentModel> get _classAssignments {
    if (_selectedClassId == null) {
      return _yearAssignments;
    }

    return _yearAssignments
        .where(
          (assignment) =>
              assignment.classId == _selectedClassId,
        )
        .toList();
  }

  // ============================================================
  // DIVISION DATA
  // ============================================================

  List<_FilterItem> get _divisionItems {
    final unique = <String, _FilterItem>{};

    for (final assignment in _classAssignments) {
      final division = assignment.division.trim();

      if (division.isEmpty) continue;

      unique[division] = _FilterItem(
        id: division,
        label: 'Division $division',
      );
    }

    final items = unique.values.toList();

    items.sort(
      (a, b) => a.label.compareTo(b.label),
    );

    return items;
  }

  List<SubjectAssignmentModel> get _divisionAssignments {
    if (_selectedDivision == null) {
      return _classAssignments;
    }

    return _classAssignments
        .where(
          (assignment) =>
              assignment.division == _selectedDivision,
        )
        .toList();
  }

  // ============================================================
  // SEMESTER DATA
  // ============================================================

  List<_FilterItem> get _semesterItems {
    final unique = <int, _FilterItem>{};

    for (final assignment in _divisionAssignments) {
      final semester = assignment.semester;

      if (semester <= 0) continue;

      unique[semester] = _FilterItem(
        id: semester.toString(),
        label: 'Semester $semester',
      );
    }

    final items = unique.values.toList();

    items.sort(
      (a, b) => int.parse(a.id).compareTo(
        int.parse(b.id),
      ),
    );

    return items;
  }

  // ============================================================
  // FINAL FILTERED ASSIGNMENTS
  // ============================================================

  List<SubjectAssignmentModel> get _filteredAssignments {
    var result = _divisionAssignments;

    if (_selectedSemester != null) {
      result = result
          .where(
            (assignment) =>
                assignment.semester == _selectedSemester,
          )
          .toList();
    }

    result.sort(
      (a, b) => a.subjectName.toLowerCase().compareTo(
            b.subjectName.toLowerCase(),
          ),
    );

    return result;
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String _classDisplayName(
    SubjectAssignmentModel assignment,
  ) {
    if (assignment.className.trim().isNotEmpty) {
      return assignment.className;
    }

    if (assignment.program.trim().isNotEmpty) {
      return assignment.program;
    }

    return 'Class';
  }

  // ============================================================
  // FILTER CHANGE
  // ============================================================

  void _resetAfterAcademicYearChange(
    String? academicYearId,
  ) {
    setState(() {
      _selectedAcademicYearId = academicYearId;
      _selectedClassId = null;
      _selectedDivision = null;
      _selectedSemester = null;
    });
  }

  void _resetAfterClassChange(String? classId) {
    setState(() {
      _selectedClassId = classId;
      _selectedDivision = null;
      _selectedSemester = null;
    });
  }

  void _resetAfterDivisionChange(String? division) {
    setState(() {
      _selectedDivision = division;
      _selectedSemester = null;
    });
  }

  void _resetAfterSemesterChange(String? semester) {
    setState(() {
      _selectedSemester =
          semester == null ? null : int.tryParse(semester);
    });
  }

  // ============================================================
  // OPEN TEACHING CONTEXT
  // ============================================================

  void _selectAssignment(
    SubjectAssignmentModel assignment,
  ) {
    if (_currentUser == null) return;

    final teachingContext = TeachingContext(
      teacherId: _currentUser!.id,
      teacherName: _currentUser!.fullName,
      assignmentId: assignment.id,
      department: assignment.department,
      program: assignment.program,
      academicYearId: assignment.academicYearId,
      academicYear: assignment.academicYear,
      classId: assignment.classId,
      className: assignment.className,
      division: assignment.division,
      semester: assignment.semester,
      subjectId: assignment.subjectId,
      subjectName: assignment.subjectName,
      subjectCode: assignment.subjectCode,
      assignmentType: assignment.assignmentType,
    );

    teachingContext.debugPrintContext();

    // Parent/dashboard can handle the selected context.
    if (widget.onContextSelected != null) {
      widget.onContextSelected!(teachingContext);
      return;
    }

    // Open actual Class Environment.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassEnvironmentScreen(
          teachingContext: teachingContext,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'My Teaching',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadTeachingAssignments,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_assignments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTeachingAssignments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildAcademicYearSelector(),

          const SizedBox(height: 14),

          _buildClassSelector(),

          const SizedBox(height: 14),

          _buildDivisionSelector(),

          const SizedBox(height: 14),

          _buildSemesterSelector(),

          const SizedBox(height: 24),

          _buildAssignmentTitle(),

          const SizedBox(height: 12),

          _buildAssignmentList(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF172554),
            Color(0xFF111827),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF334155),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF60A5FA),
              size: 28,
            ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _currentUser?.role == UserRole.hod
                      ? 'HOD • Teaching Assignments'
                      : 'Teacher • Teaching Assignments',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          _countBadge(_assignments.length),
        ],
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFF93C5FD),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // ACADEMIC YEAR
  // ============================================================

  Widget _buildAcademicYearSelector() {
    final items = _academicYearItems;

    _FilterItem? selectedItem;

    if (_selectedAcademicYearId != null) {
      for (final item in items) {
        if (item.id == _selectedAcademicYearId) {
          selectedItem = item;
          break;
        }
      }
    }

    return _buildDropdown<_FilterItem>(
      label: 'Academic Year',
      hint: 'Select academic year',
      value: selectedItem,
      items: items,
      itemLabel: (item) => item.label,
      onChanged: (item) {
        _resetAfterAcademicYearChange(item?.id);
      },
    );
  }

  // ============================================================
  // CLASS
  // ============================================================

  Widget _buildClassSelector() {
    final items = _classItems;

    _FilterItem? selectedItem;

    if (_selectedClassId != null) {
      for (final item in items) {
        if (item.id == _selectedClassId) {
          selectedItem = item;
          break;
        }
      }
    }

    return _buildDropdown<_FilterItem>(
      label: 'Class / Year',
      hint: _selectedAcademicYearId == null
          ? 'Select academic year first'
          : 'Select class / year',
      value: selectedItem,
      items: items,
      enabled: _selectedAcademicYearId != null,
      itemLabel: (item) => item.label,
      onChanged: (item) {
        _resetAfterClassChange(item?.id);
      },
    );
  }

  // ============================================================
  // DIVISION
  // ============================================================

  Widget _buildDivisionSelector() {
    final items = _divisionItems;

    _FilterItem? selectedItem;

    if (_selectedDivision != null) {
      for (final item in items) {
        if (item.id == _selectedDivision) {
          selectedItem = item;
          break;
        }
      }
    }

    return _buildDropdown<_FilterItem>(
      label: 'Division',
      hint: _selectedClassId == null
          ? 'Select class first'
          : 'Select division',
      value: selectedItem,
      items: items,
      enabled: _selectedClassId != null,
      itemLabel: (item) => item.label,
      onChanged: (item) {
        _resetAfterDivisionChange(item?.id);
      },
    );
  }

  // ============================================================
  // SEMESTER
  // ============================================================

  Widget _buildSemesterSelector() {
    final items = _semesterItems;

    _FilterItem? selectedItem;

    if (_selectedSemester != null) {
      for (final item in items) {
        if (item.id == _selectedSemester.toString()) {
          selectedItem = item;
          break;
        }
      }
    }

    return _buildDropdown<_FilterItem>(
      label: 'Semester',
      hint: _selectedDivision == null
          ? 'Select division first'
          : 'Select semester',
      value: selectedItem,
      items: items,
      enabled: _selectedDivision != null,
      itemLabel: (item) => item.label,
      onChanged: (item) {
        _resetAfterSemesterChange(item?.id);
      },
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF111827),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF64748B),
            ),
            filled: true,
            fillColor: enabled
                ? const Color(0xFF111827)
                : const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF334155),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF334155),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF94A3B8),
          ),
          items: enabled
              ? items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabel(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList()
              : null,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  // ============================================================
  // ASSIGNMENT TITLE
  // ============================================================

  Widget _buildAssignmentTitle() {
    final count = _filteredAssignments.length;

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Assigned Subjects',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count subject${count == 1 ? '' : 's'}',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ASSIGNMENT LIST
  // ============================================================

  Widget _buildAssignmentList() {
    if (_selectedAcademicYearId == null) {
      return _buildSelectionHint(
        icon: Icons.calendar_month_rounded,
        title: 'Select Academic Year',
        message:
            'Choose an academic year to see your assigned classes and subjects.',
      );
    }

    if (_selectedClassId == null) {
      return _buildSelectionHint(
        icon: Icons.school_outlined,
        title: 'Select Class / Year',
        message:
            'Choose a class or year from your assigned teaching workload.',
      );
    }

    if (_selectedDivision == null) {
      return _buildSelectionHint(
        icon: Icons.groups_rounded,
        title: 'Select Division',
        message:
            'Choose the division you are assigned to teach.',
      );
    }

    if (_selectedSemester == null) {
      return _buildSelectionHint(
        icon: Icons.menu_book_rounded,
        title: 'Select Semester',
        message:
            'Choose the semester to view assigned subjects.',
      );
    }

    if (_filteredAssignments.isEmpty) {
      return _buildSelectionHint(
        icon: Icons.search_off_rounded,
        title: 'No Subjects Found',
        message:
            'No active subject assignment matches the selected teaching context.',
      );
    }

    return Column(
      children: _filteredAssignments
          .map(_buildAssignmentCard)
          .toList(),
    );
  }

  // ============================================================
  // ASSIGNMENT CARD
  // ============================================================

  Widget _buildAssignmentCard(
    SubjectAssignmentModel assignment,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectAssignment(assignment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF2563EB).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF60A5FA),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.subjectName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        assignment.subjectCode.isEmpty
                            ? 'Subject'
                            : assignment.subjectCode,
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _infoChip(
                            Icons.school_outlined,
                            _classDisplayName(assignment),
                          ),
                          _infoChip(
                            Icons.groups_outlined,
                            'Div ${assignment.division}',
                          ),
                          _infoChip(
                            Icons.layers_outlined,
                            'Sem ${assignment.semester}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 17,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _infoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTION HINT
  // ============================================================

  Widget _buildSelectionHint({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: const Color(0xFF475569),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 38,
                color: Color(0xFF475569),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No Teaching Assignments',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'You currently have no active subjects assigned to you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _loadTeachingAssignments,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Color(0xFFEF4444),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to Load Teaching',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                height: 1.45,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadTeachingAssignments,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FILTER ITEM
// ================================================================

class _FilterItem {
  final String id;
  final String label;

  const _FilterItem({
    required this.id,
    required this.label,
  });
}