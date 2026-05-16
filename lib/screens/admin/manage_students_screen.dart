import 'package:flutter/material.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';
import 'package:studentsupportsystem/models/user_model.dart';
import 'package:studentsupportsystem/widgets/custom_card.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _dummySeeded = false;

  Future<void> _seedDummyStudents() async {
    await _firestoreService.seedDemoStudentUsers();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo students added to database with password 123456.')),
      );
    }
  }

  void _showDeleteConfirmation(UserModel student) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Student'),
          content: Text('Are you sure you want to delete ${student.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _firestoreService.deleteUser(student.uid);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Student deleted successfully')),
                  );
                }
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Students', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            onPressed: _seedDummyStudents,
            tooltip: 'Seed dummy students',
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            if (!_dummySeeded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _seedDummyStudents();
                _dummySeeded = true;
              });
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students registered yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Seeding demo students now. Refresh after a few seconds.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            );
          }

          final students = snapshot.data!;
          final Map<String, Map<String, Map<String, List<UserModel>>>> structured = {
            'IT': {
              'Sem-2': {'Div A': [], 'Div B': []},
              'Sem-4': {'Div A': [], 'Div B': []},
              'Sem-6': {'Div A': [], 'Div B': []},
            },
          };

          for (final student in students) {
            final parts = student.classGroup.split(' ');
            if (parts.length >= 4 && parts[0] == 'IT') {
              final sem = parts[1];
              final div = '${parts[2]} ${parts[3]}';
              if (structured['IT']?.containsKey(sem) ?? false) {
                structured['IT']?[sem]?[div]?.add(student);
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('IT', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...structured['IT']!.entries.map((semesterEntry) {
                final semKey = semesterEntry.key;
                final divisions = semesterEntry.value;
                final totalStudents = divisions.values.fold<int>(0, (sum, list) => sum + list.length);

                return ExpansionTile(
                  title: Text('$semKey (${totalStudents} students)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                  children: divisions.entries.map((divisionEntry) {
                    final divKey = divisionEntry.key;
                    final divisionStudents = divisionEntry.value;
                    return ExpansionTile(
                      title: Text(divKey, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      children: divisionStudents.isEmpty
                          ? [Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text('No students in $divKey yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                            )]
                          : divisionStudents.map((student) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CustomCard(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: theme.colorScheme.primary,
                                        child: Text(
                                          student.name[0].toUpperCase(),
                                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(student.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(student.email, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                            const SizedBox(height: 4),
                                            Text('Enrollment: ${student.enrollmentNumber}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(student.classGroup, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                        onPressed: () => _showDeleteConfirmation(student),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                    );
                  }).toList(),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
