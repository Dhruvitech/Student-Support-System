import 'package:flutter/material.dart';
import 'package:studentsupportsystem/screens/admin/attendance_report_screen.dart';
import 'package:studentsupportsystem/screens/admin/take_attendance_screen.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class AttendanceClassScreen extends StatefulWidget {
  const AttendanceClassScreen({super.key});

  static const classGroups = [
    'IT Sem-6 Div A',
    'IT Sem-6 Div B',
  ];

  @override
  State<AttendanceClassScreen> createState() => _AttendanceClassScreenState();
}

class _AttendanceClassScreenState extends State<AttendanceClassScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _migrationDone = false;

  @override
  void initState() {
    super.initState();
    _runMigration();
  }

  Future<void> _runMigration() async {
    if (!_migrationDone) {
      await _firestoreService.migrateOldClassNames();
      setState(() {
        _migrationDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: AttendanceClassScreen.classGroups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final classGroup = AttendanceClassScreen.classGroups[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TakeAttendanceScreen(classGroup: classGroup),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.class_, size: 40, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classGroup,
                          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to mark attendance. Use report icon to view summary.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceReportScreen(classGroup: classGroup),
                            ),
                          );
                        },
                      ),
                      const Text('Report', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
