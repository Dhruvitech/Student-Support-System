import 'package:flutter/material.dart';
import 'package:studentsupportsystem/models/attendance_model.dart';
import 'package:studentsupportsystem/models/user_model.dart';
import 'package:studentsupportsystem/screens/admin/attendance_report_screen.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final String classGroup;

  const TakeAttendanceScreen({super.key, required this.classGroup});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, bool> _attendanceMap = {};
  DateTime _selectedDate = DateTime.now();
  String? _selectedSubject;
  bool _isLoadingSubjects = true;
  List<String> _subjects = [];
  bool _isSaving = false;

  String get _formattedDate {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    var subjects = await _firestoreService.getSubjectsForClass(widget.classGroup);
    if (subjects.isEmpty) {
      subjects = ['General Subject'];
      await _firestoreService.addSubjectToClass(widget.classGroup, subjects.first);
    }
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _selectedSubject ??= _subjects.first;
      _isLoadingSubjects = false;
    });
  }

  Future<void> _addSubject() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Subject name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (result == null || result.isEmpty) return;
    if (_subjects.contains(result)) {
      if (mounted) setState(() => _selectedSubject = result);
      return;
    }
    await _firestoreService.addSubjectToClass(widget.classGroup, result);
    await _loadSubjects();
    if (mounted) setState(() => _selectedSubject = result);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _saveAttendance(List<UserModel> students) async {
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject.')),
      );
      return;
    }
    setState(() => _isSaving = true);

    for (final student in students) {
      final attendance = AttendanceModel(
        id: '${student.uid}_${widget.classGroup}_${_selectedSubject}_$_formattedDate',
        studentId: student.uid,
        studentName: student.name,
        classGroup: widget.classGroup,
        subject: _selectedSubject!,
        date: _selectedDate,
        present: _attendanceMap[student.uid] ?? false,
      );
      await _firestoreService.saveAttendanceRecord(attendance);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Attendance saved successfully!'),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'View Report',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AttendanceReportScreen(classGroup: widget.classGroup)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getStudentsByClass(widget.classGroup),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = List<UserModel>.of(snapshot.data ?? [])
            ..sort((a, b) => a.enrollmentNumber.compareTo(b.enrollmentNumber));

          for (final student in students) {
            _attendanceMap.putIfAbsent(student.uid, () => false);
          }

          final presentCount = students.where((s) => _attendanceMap[s.uid] ?? false).length;
          final total = students.length;
          final percent = total == 0 ? 0 : ((presentCount / total) * 100).round();

          return Column(
            children: [
              // ─── Header: class group, date, subject picker ───
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.class_rounded, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class Group', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                              Text(widget.classGroup, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 5),
                                Text(_formattedDate, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingSubjects)
                      const LinearProgressIndicator()
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedSubject,
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                icon: Icon(Icons.expand_more, color: theme.colorScheme.primary),
                                items: _subjects
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                                    .toList(),
                                onChanged: (value) => setState(() => _selectedSubject = value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Add Subject',
                            child: IconButton.filledTonal(
                              onPressed: _addSubject,
                              icon: const Icon(Icons.add_rounded),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ─── Stats + Quick-mark bar ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                              theme.colorScheme.secondary.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '$presentCount / $total Present',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: percent >= 75
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$percent%',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: percent >= 75 ? Colors.green.shade700 : Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => setState(() {
                        for (final s in students) {
                          _attendanceMap[s.uid] = true;
                        }
                      }),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('All ✓', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        for (final s in students) {
                          _attendanceMap[s.uid] = false;
                        }
                      }),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

              // ─── Student Grid ───
              if (students.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No students found for this class',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.83,
                    ),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isPresent = _attendanceMap[student.uid] ?? false;
                      return _buildCompactStudentCard(theme, student, isPresent);
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Builder(
        builder: (context) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final students = await _firestoreService.getStudentsByClass(widget.classGroup).first;
                      await _saveAttendance(students);
                    },
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_alt_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactStudentCard(ThemeData theme, UserModel student, bool isPresent) {
    final firstName = student.name.split(' ').first;
    final initials = student.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join('');
    final enrollSuffix = student.enrollmentNumber.length > 5
        ? student.enrollmentNumber.substring(student.enrollmentNumber.length - 5)
        : student.enrollmentNumber;

    return GestureDetector(
      onTap: () => setState(() => _attendanceMap[student.uid] = !isPresent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isPresent
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPresent ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isPresent ? 2 : 1,
          ),
          boxShadow: isPresent
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isPresent ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: isPresent ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isPresent)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                firstName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: isPresent ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '…$enrollSuffix',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isPresent
                    ? Colors.green.withValues(alpha: 0.15)
                    : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPresent ? 'Present' : 'Absent',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isPresent ? Colors.green.shade700 : theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
