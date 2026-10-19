import 'package:flutter/material.dart';

import '../../teaching_context.dart';

class ClassEnvironmentScreen extends StatelessWidget {
  const ClassEnvironmentScreen({
    super.key,
    required this.teachingContext,
  });

  final TeachingContext teachingContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Class Environment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            30,
          ),
          children: [
            _buildSubjectHeader(),

            const SizedBox(height: 16),

            _buildContextCard(),

            const SizedBox(height: 24),

            const Text(
              'Class Modules',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            _buildModuleGrid(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUBJECT HEADER
  // ============================================================

  Widget _buildSubjectHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF172554),
            Color(0xFF111827),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF60A5FA),
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teachingContext.subjectName.isEmpty
                      ? 'Subject'
                      : teachingContext.subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                if (teachingContext.subjectCode.isNotEmpty)
                  Text(
                    teachingContext.subjectCode,
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEACHING CONTEXT
  // ============================================================

  Widget _buildContextCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 20,
                color: Color(0xFF60A5FA),
              ),
              SizedBox(width: 8),
              Text(
                'Teaching Context',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _contextRow(
            Icons.calendar_month_outlined,
            'Academic Year',
            teachingContext.academicYear,
          ),

          _contextRow(
            Icons.school_outlined,
            'Program',
            teachingContext.program,
          ),

          _contextRow(
            Icons.class_outlined,
            'Class / Year',
            teachingContext.className,
          ),

          _contextRow(
            Icons.groups_outlined,
            'Division',
            teachingContext.division.isEmpty
                ? '-'
                : 'Division ${teachingContext.division}',
          ),

          _contextRow(
            Icons.layers_outlined,
            'Semester',
            teachingContext.semester > 0
                ? 'Semester ${teachingContext.semester}'
                : '-',
          ),

          _contextRow(
            Icons.category_outlined,
            'Assignment Type',
            teachingContext.assignmentType.isEmpty
                ? '-'
                : teachingContext.assignmentType,
          ),
        ],
      ),
    );
  }

  Widget _contextRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF64748B),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODULE GRID
  // ============================================================

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      _ClassModule(
        title: 'Students',
        subtitle: 'View class students',
        icon: Icons.groups_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _ClassModule(
        title: 'Attendance',
        subtitle: 'Manage class attendance',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF10B981),
      ),
      _ClassModule(
        title: 'Timetable',
        subtitle: 'View class schedule',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _ClassModule(
        title: 'Assignments',
        subtitle: 'Manage subject work',
        icon: Icons.assignment_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _ClassModule(
        title: 'Analytics',
        subtitle: 'Class performance',
        icon: Icons.analytics_rounded,
        color: const Color(0xFF06B6D4),
      ),
      _ClassModule(
        title: 'Reports',
        subtitle: 'Class reports',
        icon: Icons.description_rounded,
        color: const Color(0xFFEC4899),
      ),
      _ClassModule(
        title: 'Notices',
        subtitle: 'Class notices',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFEF4444),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        return _buildModuleCard(
          context,
          modules[index],
        );
      },
    );
  }

  // ============================================================
  // MODULE CARD
  // ============================================================

  Widget _buildModuleCard(
    BuildContext context,
    _ClassModule module,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showModuleComingSoon(
            context,
            module.title,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1E293B),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  module.icon,
                  color: module.color,
                  size: 23,
                ),
              ),

              const Spacer(),

              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                module.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEMPORARY MODULE MESSAGE
  // ============================================================

  void _showModuleComingSoon(
    BuildContext context,
    String moduleName,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111827),
        content: Text(
          '$moduleName module will use this teaching context.',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ================================================================
// CLASS MODULE MODEL
// ================================================================

class _ClassModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ClassModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}