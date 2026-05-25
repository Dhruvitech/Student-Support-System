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
  String _attendanceFilter = 'all'; // 'all', 'below_75', 'above_75'
  double _percentageThreshold = 75.0;
  late final TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _thresholdController = TextEditingController(text: '75');
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Class Group', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(widget.classGroup, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Subject', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_isLoadingSubjects)
                  const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
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
                const SizedBox(height: 16),
                Text('Attendance Filter', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _attendanceFilter == 'all',
                      onSelected: (selected) {
                        setState(() => _attendanceFilter = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Below ${_percentageThreshold.round()}%'),
                      selected: _attendanceFilter == 'below_75',
                      selectedColor: theme.colorScheme.errorContainer,
                      checkmarkColor: theme.colorScheme.error,
                      labelStyle: TextStyle(
                        color: _attendanceFilter == 'below_75' ? theme.colorScheme.error : null,
                        fontWeight: _attendanceFilter == 'below_75' ? FontWeight.bold : null,
                      ),
                      onSelected: (selected) {
                        setState(() => _attendanceFilter = 'below_75');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('${_percentageThreshold.round()}% & Above'),
                      selected: _attendanceFilter == 'above_75',
                      selectedColor: Colors.green.withValues(alpha: 0.15),
                      checkmarkColor: Colors.green.shade700,
                      labelStyle: TextStyle(
                        color: _attendanceFilter == 'above_75' ? Colors.green.shade700 : null,
                        fontWeight: _attendanceFilter == 'above_75' ? FontWeight.bold : null,
                      ),
                      onSelected: (selected) {
                        setState(() => _attendanceFilter = 'above_75');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Adjust Threshold: ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 65,
                      height: 30,
                      child: TextField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          isDense: true,
                          suffixText: '%',
                          suffixStyle: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null && parsed >= 0 && parsed <= 100) {
                            setState(() {
                              _percentageThreshold = parsed;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    thumbColor: theme.colorScheme.primary,
                  ),
                  child: Slider(
                    value: _percentageThreshold.clamp(0.0, 100.0),
                    min: 0,
                    max: 100,
                    divisions: 100, // 1% increments
                    label: '${_percentageThreshold.round()}%',
                    onChanged: (value) {
                      setState(() {
                        _percentageThreshold = value;
                        _thresholdController.text = value.round().toString();
                      });
                    },
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

                    final filteredStudents = students.where((student) {
                      final presentCount = studentReport[student.uid]?['present'] as int? ?? 0;
                      final percentage = totalLectures == 0 ? 0 : ((presentCount / totalLectures) * 100).round();

                      if (_attendanceFilter == 'below_75') {
                        return percentage < _percentageThreshold;
                      } else if (_attendanceFilter == 'above_75') {
                        return percentage >= _percentageThreshold;
                      }
                      return true; // 'all'
                    }).toList();

                    return ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: filteredStudents.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Calculate counts for summary card
                          final belowCount = students.where((student) {
                            final presentCount = studentReport[student.uid]?['present'] as int? ?? 0;
                            final percentage = totalLectures == 0 ? 0 : ((presentCount / totalLectures) * 100).round();
                            return percentage < _percentageThreshold;
                          }).length;

                          final aboveCount = students.length - belowCount;

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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Below ${_percentageThreshold.round()}%: $belowCount',
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_percentageThreshold.round()}% & Above: $aboveCount',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        final student = filteredStudents[index - 1];
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
                                backgroundColor: percentage >= _percentageThreshold ? Colors.green : theme.colorScheme.error,
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
                                        Text(
                                          'Percent: $percentage%',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: percentage >= _percentageThreshold ? Colors.green.shade700 : theme.colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
