import 'package:flutter/material.dart';

import '/subject_model.dart';
import '../../services/subject_service.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final _subjectService = SubjectService();
  bool _loading = true;
  List<SubjectModel> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // getAllSubjects() loads everything; getSubjectsByDepartment('') needs an exact match.
      final subjects = await _subjectService.getAllSubjects();
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Failed to load subjects: $e', isError: true);
    }
  }

  String? Function(String?) _required(String msg) =>
      (v) => (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _showSubjectDialog({SubjectModel? subject}) async {
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    final codeCtrl = TextEditingController(text: subject?.code ?? '');
    final deptCtrl = TextEditingController(text: subject?.department ?? '');
    final semCtrl = TextEditingController(text: subject?.semester.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? errorMessage;

    try {
      final shouldRefresh = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (_, setDialogState) {
            Future<void> save() async {
              setDialogState(() => errorMessage = null);
              if (!formKey.currentState!.validate()) return;
              setDialogState(() => isSaving = true);

              try {
                final now = DateTime.now();
                final name = nameCtrl.text.trim();
                final code = codeCtrl.text.trim().toUpperCase();
                final department = deptCtrl.text.trim();
                final semester = int.parse(semCtrl.text.trim());

                final exists = await _subjectService.subjectCodeExists(
                  code,
                  excludeSubjectId: subject?.id,
                );
                if (exists) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() {
                    isSaving = false;
                    errorMessage = 'Subject code "$code" already exists.';
                  });
                  return;
                }

                if (subject == null) {
                  await _subjectService.createSubject(SubjectModel(
                    id: '',
                    name: name,
                    code: code,
                    department: department,
                    semester: semester,
                    isActive: true,
                    createdAt: now,
                    updatedAt: now,
                  ));
                } else {
                  await _subjectService.updateSubject(subject.copyWith(
                    name: name,
                    code: code,
                    department: department,
                    semester: semester,
                    updatedAt: now,
                  ));
                }

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  isSaving = false;
                  errorMessage = 'Operation failed: $e';
                });
              }
            }

            const gap = SizedBox(height: 16);
            return AlertDialog(
              title: Text(subject == null ? 'Add Subject' : 'Edit Subject'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorMessage != null) ...[_errorBox(errorMessage!), gap],
                      _textField(
                        controller: nameCtrl,
                        enabled: !isSaving,
                        label: 'Subject Name',
                        hint: 'e.g. Data Structures',
                        icon: Icons.book_outlined,
                        validator: _required('Enter subject name'),
                      ),
                      gap,
                      _textField(
                        controller: codeCtrl,
                        enabled: !isSaving,
                        label: 'Subject Code',
                        hint: 'e.g. CS301',
                        icon: Icons.code_outlined,
                        capitalization: TextCapitalization.characters,
                        validator: _required('Enter subject code'),
                      ),
                      gap,
                      _textField(
                        controller: deptCtrl,
                        enabled: !isSaving,
                        label: 'Department',
                        hint: 'e.g. Computer Science',
                        icon: Icons.school_outlined,
                        validator: _required('Enter department'),
                      ),
                      gap,
                      _textField(
                        controller: semCtrl,
                        enabled: !isSaving,
                        label: 'Semester',
                        hint: 'e.g. 6',
                        icon: Icons.calendar_month_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final s = int.tryParse(v ?? '');
                          return (s == null || s < 1 || s > 12) ? 'Enter valid semester' : null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : save,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(subject == null ? 'Add Subject' : 'Save Changes'),
                ),
              ],
            );
          },
        ),
      );

      if (shouldRefresh == true && mounted) {
        await _loadSubjects();
        _showMessage(subject == null
            ? 'Subject added successfully.'
            : 'Subject updated successfully.');
      }
    } finally {
      for (final c in [nameCtrl, codeCtrl, deptCtrl, semCtrl]) {
        c.dispose();
      }
    }
  }

  Future<void> _toggleSubject(SubjectModel subject) async {
    try {
      await _subjectService.setSubjectStatus(subject.id, !subject.isActive);
      await _loadSubjects();
      _showMessage(subject.isActive ? 'Subject deactivated.' : 'Subject activated.');
    } catch (e) {
      _showMessage('Failed to update subject: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ));
  }

  Widget _errorBox(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
          ],
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required bool enabled,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      );

  Widget _statusBadge(bool active) {
    final color = active ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.shade700),
      ),
    );
  }

  Widget _buildSubjectCard(SubjectModel s) {
    final initials = s.code.isEmpty ? '?' : s.code.substring(0, s.code.length.clamp(0, 2));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(child: Text(initials)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      _statusBadge(s.isActive),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('${s.code} • ${s.department}',
                      style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text('Semester ${s.semester}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _showSubjectDialog(subject: s);
                if (v == 'toggle') _toggleSubject(s);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(s.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    const SizedBox(width: 10),
                    Text(s.isActive ? 'Deactivate' : 'Activate'),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Subject Management'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _loadSubjects,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : () => _showSubjectDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Subject'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadSubjects,
                child: _subjects.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Icon(Icons.menu_book_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Center(
                            child: Text('No subjects found',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ),
                          SizedBox(height: 8),
                          Center(child: Text('Tap "Add Subject" to create a subject.')),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _subjects.length,
                        itemBuilder: (_, i) => _buildSubjectCard(_subjects[i]),
                      ),
              ),
      );
}