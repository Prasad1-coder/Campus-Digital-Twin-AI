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
  State<TeacherAssignmentScreen> createState() =>
      _TeacherAssignmentScreenState();
}

class _TeacherAssignmentScreenState
    extends State<TeacherAssignmentScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final AuthService _authService = AuthService();

  final AcademicClassService _classService =
      AcademicClassService();

  final AcademicYearService _academicYearService =
      AcademicYearService();

  final SubjectService _subjectService =
      SubjectService();

  final SubjectAssignmentService _assignmentService =
      SubjectAssignmentService();

  UserModel? _currentUser;

  List<UserModel> _teachers = [];
  List<SubjectModel> _subjects = [];
  List<AcademicClassModel> _classes = [];
  List<AcademicYearModel> _academicYears = [];
  List<SubjectAssignmentModel> _assignments = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.getCurrentUser();

      if (currentUser == null) {
        throw Exception(
          'Logged-in user information not found.',
        );
      }

      _currentUser = currentUser;

      final department =
          currentUser.department.trim();

      // --------------------------------------------------------
      // LOAD TEACHERS + HODs
      // --------------------------------------------------------

      final usersSnapshot = await _firestore
          .collection('users')
          .where(
            'role',
            whereIn: ['teacher', 'hod'],
          )
          .where(
            'isActive',
            isEqualTo: true,
          )
          .get();

      final teachers = usersSnapshot.docs
          .map(
            (doc) => _userFromFirestore(
              doc.id,
              doc.data(),
            ),
          )
          .where(
            (user) =>
                user.department
                    .trim()
                    .toLowerCase() ==
                department.toLowerCase(),
          )
          .toList();

      // --------------------------------------------------------
      // LOAD SUBJECTS
      // --------------------------------------------------------

      final allSubjects =
          await _subjectService.getActiveSubjects();

      final subjects = allSubjects
          .where(
            (subject) =>
                subject.department
                    .trim()
                    .toLowerCase() ==
                department.toLowerCase(),
          )
          .toList();

      // --------------------------------------------------------
      // LOAD ACADEMIC CLASSES
      // --------------------------------------------------------

      final classes =
          await _classService.getClassesByDepartment(
        department,
      );

      final activeClasses = classes
          .where((item) => item.isActive)
          .toList();

      // --------------------------------------------------------
      // LOAD ACADEMIC YEARS
      // --------------------------------------------------------

      final academicYears =
          await _academicYearService
              .getActiveAcademicYears();

      // --------------------------------------------------------
      // LOAD EXISTING ASSIGNMENTS
      // --------------------------------------------------------

      final assignments =
          await _assignmentService
              .getDepartmentAssignments(
        department,
      );

      if (!mounted) return;

      setState(() {
        _teachers = teachers;
        _subjects = subjects;
        _classes = activeClasses;
        _academicYears = academicYears;
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Failed to load data: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // FIRESTORE USER → USER MODEL
  // ============================================================

  UserModel _userFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value) ??
            DateTime.now();
      }

      return DateTime.now();
    }

    return UserModel(
      id: id,
      collegeId:
          data['collegeId']?.toString() ?? '',
      fullName:
          data['fullName']?.toString() ??
              'Unknown User',
      email:
          data['email']?.toString() ?? '',
      password: '',
      role: _parseUserRole(
        data['role']?.toString(),
      ),
      department:
          data['department']?.toString() ??
              '',
      designation:
          data['designation']?.toString() ??
              'Teacher',
      semester:
          (data['semester'] as num?)?.toInt(),
      division:
          data['division']?.toString(),
      rollNumber:
          data['rollNumber']?.toString(),
      phoneNumber:
          data['phoneNumber']?.toString() ??
              '',
      gender:
          data['gender']?.toString() ??
              '',
      dateOfBirth:
          data['dateOfBirth'] != null
              ? parseDate(
                  data['dateOfBirth'],
                )
              : null,
      profileImageUrl:
          data['profileImageUrl']?.toString(),
      address:
          data['address']?.toString() ??
              '',
      isActive:
          data['isActive'] as bool? ??
              true,
      lastLogin:
          data['lastLogin'] != null
              ? parseDate(
                  data['lastLogin'],
                )
              : null,
      createdAt:
          parseDate(data['createdAt']),
      updatedAt:
          parseDate(data['updatedAt']),
    );
  }

  // ============================================================
  // USER ROLE PARSER
  // ============================================================

  UserRole _parseUserRole(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'student':
        return UserRole.student;

      case 'teacher':
      case 'faculty':
        return UserRole.teacher;

      case 'hod':
        return UserRole.hod;

      case 'principal':
        return UserRole.principal;

      default:
        return UserRole.teacher;
    }
  }

  // ============================================================
  // OPEN ASSIGNMENT DIALOG
  // ============================================================

  Future<void> _openAssignmentDialog({
    SubjectAssignmentModel? existingAssignment,
  }) async {
    if (_currentUser == null) return;

    String? selectedTeacherId = existingAssignment?.teacherId;
    String? selectedAcademicYearId = existingAssignment?.academicYearId;
    String? selectedClassId = existingAssignment?.classId;
    String? selectedDivision = existingAssignment?.division;
    int? selectedSemester = existingAssignment?.semester;
    String? selectedSubjectId = existingAssignment?.subjectId;
    String selectedAssignmentType =
        existingAssignment?.assignmentType.isNotEmpty == true
            ? existingAssignment!.assignmentType
            : 'regular';

    if (selectedAcademicYearId == null && _academicYears.isNotEmpty) {
      final current = _academicYears.where((y) => y.isCurrent);
      selectedAcademicYearId =
          current.isNotEmpty ? current.first.id : _academicYears.first.id;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            AcademicClassModel? selectedClass;
            if (selectedClassId != null) {
              for (final item in _classes) {
                if (item.id == selectedClassId) {
                  selectedClass = item;
                  break;
                }
              }
            }

            final divisions = selectedClass?.divisions ?? <String>[];
            final semesters = selectedClass?.semesters ?? <int>[];

            if (selectedDivision != null &&
                !divisions.contains(selectedDivision)) {
              selectedDivision = null;
            }
            if (selectedSemester != null &&
                !semesters.contains(selectedSemester)) {
              selectedSemester = null;
              selectedSubjectId = null;
            }

            final availableSubjects = _subjects.where((subject) {
              final sameDepartment = subject.department.trim().toLowerCase() ==
                  _currentUser!.department.trim().toLowerCase();
              final sameSemester = selectedSemester == null ||
                  subject.semester == selectedSemester;
              return sameDepartment && sameSemester;
            }).toList();

            if (selectedSubjectId != null &&
                !availableSubjects.any((s) => s.id == selectedSubjectId)) {
              selectedSubjectId = null;
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(existingAssignment == null
                      ? Icons.assignment_ind_outlined
                      : Icons.edit_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(existingAssignment == null
                        ? 'Assign Subject'
                        : 'Edit Assignment'),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedTeacherId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Teacher / HOD',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: _teachers.map((teacher) {
                          return DropdownMenuItem<String>(
                            value: teacher.id,
                            child: Text(
                              '${teacher.fullName} (${teacher.designation})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedTeacherId = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedAcademicYearId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _academicYears.map((year) {
                          return DropdownMenuItem<String>(
                            value: year.id,
                            child: Text(
                              year.isCurrent ? '${year.name} (Current)' : year.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _academicYears.isEmpty
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedAcademicYearId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedClassId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Class / Program',
                          prefixIcon: Icon(Icons.school_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _classes.map((academicClass) {
                          return DropdownMenuItem<String>(
                            value: academicClass.id,
                            child: Text(
                              '${academicClass.program} • ${academicClass.yearName}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _classes.isEmpty
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedClassId = value;
                                  selectedDivision = null;
                                  selectedSemester = null;
                                  selectedSubjectId = null;
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedDivision,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Division',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: divisions.map((division) {
                          return DropdownMenuItem<String>(
                            value: division,
                            child: Text('Division $division'),
                          );
                        }).toList(),
                        onChanged: selectedClass == null
                            ? null
                            : (value) {
                                setDialogState(() => selectedDivision = value);
                              },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        initialValue: selectedSemester,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          prefixIcon: Icon(Icons.format_list_numbered),
                          border: OutlineInputBorder(),
                        ),
                        items: semesters.map((semester) {
                          return DropdownMenuItem<int>(
                            value: semester,
                            child: Text('Semester $semester'),
                          );
                        }).toList(),
                        onChanged: selectedClass == null
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedSemester = value;
                                  selectedSubjectId = null;
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedSubjectId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: availableSubjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject.id,
                            child: Text(
                              '${subject.code} • ${subject.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: selectedSemester == null
                            ? null
                            : (value) {
                                setDialogState(() => selectedSubjectId = value);
                              },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedAssignmentType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assignment Type',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'regular', child: Text('Regular')),
                          DropdownMenuItem(value: 'lab', child: Text('Lab')),
                          DropdownMenuItem(value: 'elective', child: Text('Elective')),
                          DropdownMenuItem(value: 'substitute', child: Text('Substitute')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedAssignmentType = value);
                          }
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
                  icon: const Icon(Icons.save_outlined),
                  label: Text(existingAssignment == null ? 'Assign' : 'Update'),
                  onPressed: () async {
                    if (selectedTeacherId == null ||
                        selectedAcademicYearId == null ||
                        selectedClassId == null ||
                        selectedDivision == null ||
                        selectedSemester == null ||
                        selectedSubjectId == null) {
                      _showSnackBar(
                        'Please select Teacher, Academic Year, Class, Division, Semester and Subject.',
                        isError: true,
                      );
                      return;
                    }

                    UserModel? teacher;
                    AcademicYearModel? academicYear;
                    AcademicClassModel? academicClass;
                    SubjectModel? subject;

                    for (final item in _teachers) {
                      if (item.id == selectedTeacherId) {
                        teacher = item;
                        break;
                      }
                    }
                    for (final item in _academicYears) {
                      if (item.id == selectedAcademicYearId) {
                        academicYear = item;
                        break;
                      }
                    }
                    for (final item in _classes) {
                      if (item.id == selectedClassId) {
                        academicClass = item;
                        break;
                      }
                    }
                    for (final item in _subjects) {
                      if (item.id == selectedSubjectId) {
                        subject = item;
                        break;
                      }
                    }

                    if (teacher == null ||
                        academicYear == null ||
                        academicClass == null ||
                        subject == null) {
                      _showSnackBar(
                        'Selected data is no longer available. Refresh and try again.',
                        isError: true,
                      );
                      return;
                    }

                    final duplicate = _assignments.any((assignment) =>
                        assignment.id != existingAssignment?.id &&
                        assignment.isActive &&
                        assignment.teacherId == teacher!.id &&
                        assignment.subjectId == subject!.id &&
                        assignment.classId == academicClass!.id &&
                        assignment.division == selectedDivision &&
                        assignment.semester == selectedSemester &&
                        assignment.academicYearId == academicYear!.id);

                    if (duplicate) {
                      _showSnackBar(
                        'This subject is already assigned to this teacher for the selected class, division, semester and academic year.',
                        isError: true,
                      );
                      return;
                    }

                    try {
                      final now = DateTime.now();

                      final assignment = SubjectAssignmentModel(
                        id: existingAssignment?.id ?? '',
                        teacherId: teacher.id,
                        teacherName: teacher.fullName,
                        subjectId: subject.id,
                        subjectName: subject.name,
                        subjectCode: subject.code,
                        department: _currentUser!.department,
                        classId: academicClass.id,
                        className: academicClass.yearName,
                        program: academicClass.program,
                        division: selectedDivision!,
                        semester: selectedSemester!,
                        academicYearId: academicYear.id,
                        academicYear: academicYear.name,
                        assignmentType: selectedAssignmentType,
                        startDate: existingAssignment?.startDate ?? now,
                        endDate: existingAssignment?.endDate,
                        assignedBy: _currentUser!.id,
                        assignedByName: _currentUser!.fullName,
                        isActive: true,
                        createdAt: existingAssignment?.createdAt ?? now,
                        updatedAt: now,
                      );

                      if (existingAssignment == null) {
                        await _assignmentService.createAssignment(assignment);
                      } else {
                        await _assignmentService.updateAssignment(assignment);
                      }

                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadData();

                      _showSnackBar(
                        existingAssignment == null
                            ? 'Subject assigned successfully.'
                            : 'Assignment updated successfully.',
                      );
                    } catch (e) {
                      _showSnackBar(
                        'Failed to save assignment:\n$e',
                        isError: true,
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TOGGLE ASSIGNMENT
  // ============================================================

  Future<void> _toggleAssignment(
    SubjectAssignmentModel assignment,
  ) async {
    try {
      await _assignmentService
          .setAssignmentStatus(
        assignment.id,
        !assignment.isActive,
      );

      await _loadData();

      _showSnackBar(
        assignment.isActive
            ? 'Assignment deactivated.'
            : 'Assignment activated.',
      );
    } catch (e) {
      _showSnackBar(
        'Failed to update assignment: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteAssignment(
    SubjectAssignmentModel assignment,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Delete Assignment'),
          content: Text(
            'Delete ${assignment.subjectName} assignment for ${assignment.teacherName}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _assignmentService
          .deleteAssignment(
        assignment.id,
      );

      await _loadData();

      _showSnackBar(
        'Assignment deleted.',
      );
    } catch (e) {
      _showSnackBar(
        'Failed to delete assignment: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  void _showDialogError(
    BuildContext context,
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            isError
                ? Colors.red.shade700
                : null,
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Assignment',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _loadData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _isLoading
                ? null
                : () =>
                    _openAssignmentDialog(),
        icon: const Icon(
          Icons.add,
        ),
        label:
            const Text(
          'Assign Subject',
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child:
                  _buildAssignmentList(),
            ),
    );
  }

  // ============================================================
  // ASSIGNMENT LIST
  // ============================================================

  Widget _buildAssignmentList() {
    if (_assignments.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.25,
          ),
          const Icon(
            Icons.assignment_outlined,
            size: 64,
          ),
          const SizedBox(
            height: 16,
          ),
          const Center(
            child: Text(
              'No subject assignments found.',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Center(
            child: Text(
              'Tap "Assign Subject" to create one.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.all(16),
      itemCount:
          _assignments.length,
      itemBuilder:
          (context, index) {
        final assignment =
            _assignments[index];

        return _buildAssignmentCard(
          assignment,
        );
      },
    );
  }

  // ============================================================
  // ASSIGNMENT CARD
  // ============================================================

  Widget _buildAssignmentCard(
    SubjectAssignmentModel assignment,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons
                        .menu_book_outlined,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        assignment
                            .subjectName,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        assignment
                            .subjectCode,
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected:
                      (value) {
                    if (value ==
                        'edit') {
                      _openAssignmentDialog(
                        existingAssignment:
                            assignment,
                      );
                    } else if (value ==
                        'toggle') {
                      _toggleAssignment(
                        assignment,
                      );
                    } else if (value ==
                        'delete') {
                      _deleteAssignment(
                        assignment,
                      );
                    }
                  },
                  itemBuilder:
                      (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .edit_outlined,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value:
                          'toggle',
                      child: Row(
                        children: [
                          Icon(
                            assignment
                                    .isActive
                                ? Icons
                                    .pause_circle_outline
                                : Icons
                                    .play_circle_outline,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            assignment
                                    .isActive
                                ? 'Deactivate'
                                : 'Activate',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value:
                          'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(
              height: 24,
            ),

            // --------------------------------------------------
            // TEACHER
            // --------------------------------------------------

            _infoRow(
              Icons.person_outline,
              'Teacher',
              assignment.teacherName,
            ),

            const SizedBox(
              height: 8,
            ),

            // --------------------------------------------------
            // PROGRAM / CLASS
            // --------------------------------------------------

            _infoRow(
              Icons.school_outlined,
              'Class',
              assignment.program.isNotEmpty
                  ? '${assignment.program} • ${assignment.className}'
                  : assignment.className,
            ),

            const SizedBox(
              height: 8,
            ),

            // --------------------------------------------------
            // DIVISION / SEMESTER
            // --------------------------------------------------

            _infoRow(
              Icons.groups_outlined,
              'Section',
              'Division ${assignment.division} • Semester ${assignment.semester}',
            ),

            const SizedBox(
              height: 8,
            ),

            // --------------------------------------------------
            // ACADEMIC YEAR
            // --------------------------------------------------

            _infoRow(
              Icons.calendar_today_outlined,
              'Academic Year',
              assignment.academicYear,
            ),

            const SizedBox(
              height: 8,
            ),

            // --------------------------------------------------
            // TYPE
            // --------------------------------------------------

            _infoRow(
              Icons.category_outlined,
              'Type',
              _formatAssignmentType(
                assignment.assignmentType,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // --------------------------------------------------
            // STATUS
            // --------------------------------------------------

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        assignment.isActive
                            ? Colors
                                .green
                                .withValues(
                                alpha: 0.12,
                              )
                            : Colors
                                .red
                                .withValues(
                                alpha: 0.12,
                              ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child: Text(
                    assignment.isActive
                        ? 'ACTIVE'
                        : 'INACTIVE',
                    style:
                        TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          assignment
                                  .isActive
                              ? Colors
                                  .green
                              : Colors
                                  .red,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    'Assigned by ${assignment.assignedByName}',
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color:
              Colors.grey.shade600,
        ),
        const SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style:
                TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORMAT TYPE
  // ============================================================

  String _formatAssignmentType(
    String type,
  ) {
    if (type.isEmpty) {
      return 'Regular';
    }

    return type[0].toUpperCase() +
        type.substring(1);
  }
}

// ================================================================
// HELPER EXTENSION
// ================================================================

extension FirstOrNullExtension<T>
    on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }

    return first;
  }
}