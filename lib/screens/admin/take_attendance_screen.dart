import 'package:flutter/material.dart';
import 'package:studentsupportsystem/models/attendance_model.dart';
import 'package:studentsupportsystem/models/user_model.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';
import 'package:studentsupportsystem/screens/admin/attendance_report_screen.dart';

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
  bool _demoStudentsSeeded = false;

  static const Map<String, List<String>> classSubjects = {
    'IT Sem-6 Div A': ['Advanced Web Development', 'Artificial Intelligence', 'Software Engineering', 'Data Analysis and Visualization'],
    'IT Sem-6 Div B': ['Advanced Web Development', 'Artificial Intelligence', 'Software Engineering', 'Data Analysis and Visualization'],
  };

  String get _formattedDate {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _saveAttendance(List<UserModel> students) async {
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject.')),
      );
      return;
    }

    for (final student in students) {
      final attendance = AttendanceModel(
        id: '${student.uid}_${widget.classGroup}_${_selectedSubject}_${_formattedDate}',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully.')),
      );
    }
  }

  Future<void> _seedDemoStudents() async {
    await _firestoreService.seedDemoStudentUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo students added to users collection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = classSubjects[widget.classGroup] ?? [];
    _selectedSubject ??= subjects.isNotEmpty ? subjects.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(widget.classGroup, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text('Select date', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formattedDate, style: theme.textTheme.bodyLarge),
                        Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Select subject', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: subjects.map((subject) => DropdownMenuItem(value: subject, child: Text(subject))).toList(),
                    onChanged: (value) => setState(() => _selectedSubject = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firestoreService.getStudentsByClass(widget.classGroup),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data ?? [];
                students.sort((a, b) => a.enrollmentNumber.compareTo(b.enrollmentNumber));
                if (students.isEmpty) {
                  if (!_demoStudentsSeeded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _seedDemoStudents();
                      setState(() {
                        _demoStudentsSeeded = true;
                      });
                    });
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No students found for this class. Demo students will be added to the users collection now.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _seedDemoStudents,
                            child: const Text('Add demo students now'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                for (final student in students) {
                  _attendanceMap.putIfAbsent(student.uid, () => false);
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isPresent = _attendanceMap[student.uid] ?? false;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: CheckboxListTile(
                        value: isPresent,
                        title: Text(student.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('${student.enrollmentNumber} • ${student.email}', style: theme.textTheme.bodySmall),
                        secondary: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(student.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _attendanceMap[student.uid] = value ?? false;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceReportScreen(classGroup: widget.classGroup),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('Report'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final students = await _firestoreService.getStudentsByClass(widget.classGroup).first;
                  await _saveAttendance(students);
                },
                icon: const Icon(Icons.save_alt),
                label: const Text('Save Attendance'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
