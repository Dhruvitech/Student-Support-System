import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/models/attendance_model.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Attendance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: user == null
          ? Center(
              child: Text('Please sign in to view attendance.', style: theme.textTheme.titleMedium),
            )
          : StreamBuilder<List<String>>(
              stream: firestoreService.getSubjectsStreamForClass(user.classGroup),
              builder: (context, subjectSnapshot) {
                if (subjectSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final subjects = subjectSnapshot.data ?? ['General Subject'];
                final activeSubject = subjects.contains(_selectedSubject) ? _selectedSubject! : subjects.first;

                return StreamBuilder<List<AttendanceModel>>(
                  stream: firestoreService.getAttendanceRecordsForClassAndSubject(user.classGroup, activeSubject),
                  builder: (context, attendanceSnapshot) {
                    if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final attendanceRecords = attendanceSnapshot.data ?? [];
                    
                    // Extract unique lecture dates
                    final lectureDates = attendanceRecords
                        .map((r) => r.date.toIso8601String().split('T').first)
                        .toSet();
                    final total = lectureDates.length;

                    // Match daily records for the current student
                    final List<AttendanceModel> studentDailyRecords = [];
                    final sortedDates = lectureDates.toList()..sort((a, b) => b.compareTo(a));

                    for (final dateStr in sortedDates) {
                      final recordOnDate = attendanceRecords.firstWhere(
                        (r) => (r.studentId == user.uid || r.studentName == user.name) && 
                               r.date.toIso8601String().startsWith(dateStr),
                        orElse: () => AttendanceModel(
                          id: 'missing_${user.uid}_${dateStr}',
                          studentId: user.uid,
                          studentName: user.name,
                          classGroup: user.classGroup,
                          subject: activeSubject,
                          date: DateTime.parse(dateStr),
                          present: false, // Default to absent if missing
                        ),
                      );
                      studentDailyRecords.add(recordOnDate);
                    }

                    final present = studentDailyRecords.where((r) => r.present).length;
                    final percent = total == 0 ? 0 : ((present / total) * 100).round();

                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text('Select Subject', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
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
                            value: activeSubject,
                            items: subjects
                                .map((subject) => DropdownMenuItem(value: subject, child: Text(subject)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubject = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSubjectSummaryCard(context, theme, activeSubject, present, total, percent),
                        const SizedBox(height: 12),
                        _buildAttendanceDetails(context, theme, studentDailyRecords),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSubjectSummaryCard(BuildContext context, ThemeData theme, String subject, int present, int total, int percent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percent% Attendance', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$present / $total Lectures',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percent / 100,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDetails(BuildContext context, ThemeData theme, List<AttendanceModel> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Attendance Log', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No logs for this subject.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          )
        else
          ...records.map((record) {
            final dateLabel = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
            final statusColor = record.present ? theme.colorScheme.primary : theme.colorScheme.error;
            final statusBg = record.present 
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15) 
                : theme.colorScheme.errorContainer.withValues(alpha: 0.15);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: statusBg,
                    child: Icon(
                      record.present ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          record.present ? 'Attended' : 'Missed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      record.present ? 'Present' : 'Absent',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}
