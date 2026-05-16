import 'package:flutter/material.dart';
import 'package:studentsupportsystem/models/user_model.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class StudentGroupsScreen extends StatelessWidget {
  const StudentGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Groups', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return Center(
              child: Text(
                'No students are registered yet.',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                textAlign: TextAlign.center,
              ),
            );
          }

          final Map<String, List<UserModel>> grouped = {};
          for (final student in students) {
            final groupName = student.classGroup.isNotEmpty ? student.classGroup : 'Unassigned';
            grouped.putIfAbsent(groupName, () => []).add(student);
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: grouped.entries.map((entry) {
              final groupName = entry.key;
              final groupStudents = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...groupStudents.map((student) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
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
                                Text(student.email, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                const SizedBox(height: 4),
                                Text('Password: 123456', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
