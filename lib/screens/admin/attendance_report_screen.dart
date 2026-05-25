import 'package:flutter/material.dart';
import 'package:studentsupportsystem/models/attendance_model.dart';
import 'package:studentsupportsystem/models/user_model.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  final String classGroup;

  const AttendanceReportScreen({super.key, required this.classGroup});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedSubject;
  List<String> _subjects = [];
  bool _isLoadingSubjects = true;

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

    if (!mounted) {
      return;
    }

    setState(() {
      _subjects = subjects;
      _selectedSubject = _subjects.first;
      _isLoadingSubjects = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Report', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class Group', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(widget.classGroup, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Subject', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_isLoadingSubjects)
                  const SizedBox(height: 58, child: Center(child: CircularProgressIndicator()))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      value: _selectedSubject,
                      items: _subjects
                          .map((subject) => DropdownMenuItem(value: subject, child: Text(subject)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedSubject = value),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firestoreService.getStudentsByClass(widget.classGroup),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = List<UserModel>.from(studentSnapshot.data ?? [])
                  ..sort((a, b) => a.enrollmentNumber.compareTo(b.enrollmentNumber));
                if (students.isEmpty) {
                  return Center(
                    child: Text(
                      'No students found in this class yet.',
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  );
                }

                return StreamBuilder<List<AttendanceModel>>(
                  stream: _firestoreService.getAttendanceRecordsForClassAndSubject(widget.classGroup, _selectedSubject ?? ''),
                  builder: (context, attendanceSnapshot) {
                    if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final attendanceRecords = attendanceSnapshot.data ?? [];
                    final lectureDates = attendanceRecords.map((record) => record.date.toIso8601String().split('T').first).toSet();
                    final totalLectures = lectureDates.length;

                    final studentReport = {
                      for (final student in students)
                        student.uid: {
                          'student': student,
                          'present': attendanceRecords
                              .where((record) => record.studentId == student.uid && record.present)
                              .length,
                        }
                    };

                    return ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: students.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Report summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Text('Total lectures: $totalLectures', style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          );
                        }

                        final student = students[index - 1];
                        final presentCount = studentReport[student.uid]?['present'] as int? ?? 0;
                        final percentage = totalLectures == 0 ? 0 : ((presentCount / totalLectures) * 100).round();

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(student.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(student.enrollmentNumber, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text('Present: $presentCount', style: theme.textTheme.bodySmall),
                                        const SizedBox(width: 12),
                                        Text('Percent: $percentage%', style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
