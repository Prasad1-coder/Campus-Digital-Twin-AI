import 'package:flutter/material.dart';

import '/subject_model.dart';
import '../../services/subject_service.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState
    extends State<SubjectManagementScreen> {
  final SubjectService _subjectService = SubjectService();

  bool _loading = true;
  List<SubjectModel> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  // ============================================================
  // LOAD ALL SUBJECTS
  // ============================================================

  Future<void> _loadSubjects() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      // IMPORTANT:
      // Do NOT use getSubjectsByDepartment('') here.
      // It requires an exact department match.
      //
      // getAllSubjects() loads all subjects from Firestore.
      final subjects = await _subjectService.getAllSubjects();

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Failed to load subjects: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // ADD / EDIT SUBJECT
  // ============================================================

  Future<void> _showSubjectDialog({
    SubjectModel? subject,
  }) async {
    final nameController = TextEditingController(
      text: subject?.name ?? '',
    );

    final codeController = TextEditingController(
      text: subject?.code ?? '',
    );

    final departmentController = TextEditingController(
      text: subject?.department ?? '',
    );

    final semesterController = TextEditingController(
      text: subject != null
          ? subject.semester.toString()
          : '',
    );

    final formKey = GlobalKey<FormState>();

    bool isSaving = false;
    String? errorMessage;

    try {
      final shouldRefresh = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              dialogViewContext,
              setDialogState,
            ) {
              return AlertDialog(
                title: Text(
                  subject == null
                      ? 'Add Subject'
                      : 'Edit Subject',
                ),

                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==================================================
                        // ERROR MESSAGE
                        // ==================================================

                        if (errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Colors.red.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    Colors.red.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ==================================================
                        // SUBJECT NAME
                        // ==================================================

                        TextFormField(
                          controller: nameController,
                          enabled: !isSaving,
                          decoration:
                              const InputDecoration(
                            labelText: 'Subject Name',
                            hintText:
                                'e.g. Data Structures',
                            prefixIcon: Icon(
                              Icons.book_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter subject name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // SUBJECT CODE
                        // ==================================================

                        TextFormField(
                          controller: codeController,
                          enabled: !isSaving,
                          textCapitalization:
                              TextCapitalization.characters,
                          decoration:
                              const InputDecoration(
                            labelText: 'Subject Code',
                            hintText: 'e.g. CS301',
                            prefixIcon: Icon(
                              Icons.code_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter subject code';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DEPARTMENT
                        // ==================================================

                        TextFormField(
                          controller:
                              departmentController,
                          enabled: !isSaving,
                          decoration:
                              const InputDecoration(
                            labelText: 'Department',
                            hintText:
                                'e.g. Computer Science',
                            prefixIcon: Icon(
                              Icons.school_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter department';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // SEMESTER
                        // ==================================================

                        TextFormField(
                          controller:
                              semesterController,
                          enabled: !isSaving,
                          keyboardType:
                              TextInputType.number,
                          decoration:
                              const InputDecoration(
                            labelText: 'Semester',
                            hintText: 'e.g. 6',
                            prefixIcon: Icon(
                              Icons
                                  .calendar_month_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final semester =
                                int.tryParse(
                              value ?? '',
                            );

                            if (semester == null ||
                                semester < 1 ||
                                semester > 12) {
                              return 'Enter valid semester';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ==========================================================
                // ACTIONS
                // ==========================================================

                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.of(
                              dialogContext,
                            ).pop(false);
                          },
                    child: const Text('Cancel'),
                  ),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            // Clear previous error.
                            setDialogState(() {
                              errorMessage = null;
                            });

                            // Validate form.
                            if (!formKey.currentState!
                                .validate()) {
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            try {
                              final now =
                                  DateTime.now();

                              final name =
                                  nameController.text
                                      .trim();

                              final code =
                                  codeController.text
                                      .trim()
                                      .toUpperCase();

                              final department =
                                  departmentController.text
                                      .trim();

                              final semester =
                                  int.parse(
                                semesterController.text
                                    .trim(),
                              );

                              // =================================================
                              // CHECK DUPLICATE CODE
                              // =================================================

                              final exists =
                                  await _subjectService
                                      .subjectCodeExists(
                                code,
                                excludeSubjectId:
                                    subject?.id,
                              );

                              if (exists) {
                                if (!dialogContext
                                    .mounted) {
                                  return;
                                }

                                setDialogState(() {
                                  isSaving = false;
                                  errorMessage =
                                      'Subject code "$code" already exists.';
                                });

                                return;
                              }

                              // =================================================
                              // CREATE
                              // =================================================

                              if (subject == null) {
                                final newSubject =
                                    SubjectModel(
                                  id: '',
                                  name: name,
                                  code: code,
                                  department:
                                      department,
                                  semester: semester,
                                  isActive: true,
                                  createdAt: now,
                                  updatedAt: now,
                                );

                                await _subjectService
                                    .createSubject(
                                  newSubject,
                                );
                              }

                              // =================================================
                              // UPDATE
                              // =================================================

                              else {
                                final updatedSubject =
                                    subject.copyWith(
                                  name: name,
                                  code: code,
                                  department:
                                      department,
                                  semester: semester,
                                  updatedAt: now,
                                );

                                await _subjectService
                                    .updateSubject(
                                  updatedSubject,
                                );
                              }

                              // =================================================
                              // CLOSE DIALOG
                              // =================================================

                              if (!dialogContext
                                  .mounted) {
                                return;
                              }

                              Navigator.of(
                                dialogContext,
                              ).pop(true);
                            } catch (e) {
                              if (!dialogContext
                                  .mounted) {
                                return;
                              }

                              setDialogState(() {
                                isSaving = false;
                                errorMessage =
                                    'Operation failed: $e';
                              });
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            subject == null
                                ? 'Add Subject'
                                : 'Save Changes',
                          ),
                  ),
                ],
              );
            },
          );
        },
      );

      // ==============================================================
      // DIALOG CLOSED → REFRESH LIST
      // ==============================================================

      if (shouldRefresh == true && mounted) {
        await _loadSubjects();

        if (!mounted) return;

        _showMessage(
          subject == null
              ? 'Subject added successfully.'
              : 'Subject updated successfully.',
        );
      }
    } finally {
      nameController.dispose();
      codeController.dispose();
      departmentController.dispose();
      semesterController.dispose();
    }
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

  Future<void> _toggleSubject(
    SubjectModel subject,
  ) async {
    try {
      await _subjectService.setSubjectStatus(
        subject.id,
        !subject.isActive,
      );

      await _loadSubjects();

      if (!mounted) return;

      _showMessage(
        subject.isActive
            ? 'Subject deactivated.'
            : 'Subject activated.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to update subject: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  // ============================================================
  // SUBJECT CARD
  // ============================================================

  Widget _buildSubjectCard(
    SubjectModel subject,
  ) {
    final initials = subject.code.isNotEmpty
        ? subject.code.substring(
            0,
            subject.code.length > 2
                ? 2
                : subject.code.length,
          )
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ========================================================
            // ICON
            // ========================================================

            CircleAvatar(
              child: Text(initials),
            ),

            const SizedBox(width: 16),

            // ========================================================
            // SUBJECT DETAILS
            // ========================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      // ACTIVE / INACTIVE
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: subject.isActive
                              ? Colors.green
                                  .withOpacity(0.10)
                              : Colors.red
                                  .withOpacity(0.10),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          subject.isActive
                              ? 'Active'
                              : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                            color: subject.isActive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${subject.code} • '
                    '${subject.department}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Semester ${subject.semester}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // ========================================================
            // MENU
            // ========================================================

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showSubjectDialog(
                    subject: subject,
                  );
                }

                if (value == 'toggle') {
                  _toggleSubject(subject);
                }
              },
              itemBuilder: (menuContext) {
                return [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                        ),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          subject.isActive
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          subject.isActive
                              ? 'Deactivate'
                              : 'Activate',
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
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
      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text(
          'Subject Management',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _loading ? null : _loadSubjects,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // ==========================================================
      // ADD SUBJECT
      // ==========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _loading
            ? null
            : () {
                _showSubjectDialog();
              },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Subject',
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _subjects.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadSubjects,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 180,
                      ),

                      Icon(
                        Icons
                            .menu_book_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),

                      SizedBox(
                        height: 16,
                      ),

                      Center(
                        child: Text(
                          'No subjects found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 8,
                      ),

                      Center(
                        child: Text(
                          'Tap "Add Subject" to create a subject.',
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubjects,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      100,
                    ),
                    itemCount:
                        _subjects.length,
                    itemBuilder:
                        (context, index) {
                      return _buildSubjectCard(
                        _subjects[index],
                      );
                    },
                  ),
                ),
    );
  }
}