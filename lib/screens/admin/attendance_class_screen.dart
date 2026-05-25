import 'package:flutter/material.dart';
import 'package:studentsupportsystem/screens/admin/attendance_report_screen.dart';
import 'package:studentsupportsystem/screens/admin/take_attendance_screen.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class AttendanceClassScreen extends StatefulWidget {
  const AttendanceClassScreen({super.key});

  @override
  State<AttendanceClassScreen> createState() => _AttendanceClassScreenState();
}

class _AttendanceClassScreenState extends State<AttendanceClassScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _showAddClassDialog() async {
    final isAdded = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _AddClassDialog(
          onAdd: (branch, semester, division) async {
            await _firestoreService.createClassGroup(
              branch: branch,
              semester: semester,
              division: division,
            );
          },
        );
      },
    );

    if (isAdded == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Class added successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Class'),
      ),
      body: StreamBuilder<List<String>>(
        stream: _firestoreService.getClassGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load classes right now.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          final classGroups = snapshot.data ?? [];

          if (classGroups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.class_outlined, size: 48, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No classes added yet.',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Add Class" to create your first class.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: classGroups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final classGroup = classGroups[index];
              return _ClassGroupCard(
                classGroup: classGroup,
                theme: theme,
                onTakeTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TakeAttendanceScreen(classGroup: classGroup),
                  ),
                ),
                onReportTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceReportScreen(classGroup: classGroup),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClassGroupCard extends StatelessWidget {
  final String classGroup;
  final ThemeData theme;
  final VoidCallback onTakeTap;
  final VoidCallback onReportTap;

  const _ClassGroupCard({
    required this.classGroup,
    required this.theme,
    required this.onTakeTap,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    // Pick gradient colors by class group for variety
    final List<List<Color>> gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFFEC4899), const Color(0xFFDB2777)],
    ];
    final gradientColors = gradients[classGroup.hashCode.abs() % gradients.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTakeTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classGroup,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to mark attendance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
                    onPressed: onReportTap,
                    tooltip: 'View Report',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Report', style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddClassDialog extends StatefulWidget {
  final Future<void> Function(String branch, int semester, String division) onAdd;

  const _AddClassDialog({required this.onAdd});

  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _divisionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onAdd(
        _branchController.text.trim(),
        int.parse(_semesterController.text.trim()),
        _divisionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  void dispose() {
    _branchController.dispose();
    _semesterController.dispose();
    _divisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Class'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(labelText: 'Branch', hintText: 'e.g. IT, CSE'),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a branch' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _semesterController,
                decoration: const InputDecoration(labelText: 'Semester', hintText: 'e.g. 6'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Enter a semester';
                  final semester = int.tryParse(value!.trim());
                  if (semester == null || semester <= 0) return 'Enter a valid semester';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _divisionController,
                decoration: const InputDecoration(labelText: 'Division', hintText: 'e.g. A, B, C'),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a division' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }
}
