import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/models/attendance_model.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

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
          : StreamBuilder<List<AttendanceModel>>(
              stream: firestoreService.getAttendanceForStudent(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final attendanceRecords = snapshot.data ?? [];
                if (attendanceRecords.isEmpty) {
                  return Center(
                    child: Text(
                      'No attendance data available yet. Ask your faculty to mark attendance for your class.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  );
                }

                final totalLectures = attendanceRecords.length;
                final totalPresent = attendanceRecords.where((record) => record.present).length;
                final overallPercentage = totalLectures == 0 ? 0 : ((totalPresent / totalLectures) * 100).round();

                final bySubject = <String, List<AttendanceModel>>{};
                for (final record in attendanceRecords) {
                  bySubject.putIfAbsent(record.subject, () => []).add(record);
                }

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSummaryCard(context, theme, totalLectures, totalPresent, overallPercentage),
                    const SizedBox(height: 20),
                    ...bySubject.entries.map((entry) => _buildSubjectCard(context, theme, entry.key, entry.value)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ThemeData theme, int totalLectures, int totalPresent, int overallPercentage) {
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
          Text('Overall Attendance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('$overallPercentage%', style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$totalPresent of $totalLectures lectures present', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: overallPercentage / 100),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, ThemeData theme, String subject, List<AttendanceModel> records) {
    final total = records.length;
    final present = records.where((item) => item.present).length;
    final percent = total == 0 ? 0 : (present / total * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$percent% attendance', style: theme.textTheme.bodyMedium),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$present / $total', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: records.map((record) {
                final dateLabel = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: record.present ? theme.colorScheme.primary : theme.colorScheme.error,
                        child: Icon(record.present ? Icons.check : Icons.close, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(dateLabel, style: theme.textTheme.bodyMedium),
                      ),
                      Text(record.present ? 'Present' : 'Absent', style: theme.textTheme.bodyMedium?.copyWith(color: record.present ? theme.colorScheme.primary : theme.colorScheme.error)),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }


}
