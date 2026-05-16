import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/providers/schedule_provider.dart';
import 'package:studentsupportsystem/models/schedule_model.dart';
import 'package:studentsupportsystem/widgets/custom_card.dart';
import 'package:studentsupportsystem/widgets/custom_textfield.dart';

class ClassScheduleAdminScreen extends StatefulWidget {
  const ClassScheduleAdminScreen({super.key});

  @override
  State<ClassScheduleAdminScreen> createState() => _ClassScheduleAdminScreenState();
}

class _ClassScheduleAdminScreenState extends State<ClassScheduleAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().listenToSchedules();
    });
  }

  void _showAddScheduleDialog() {
    final subjectController = TextEditingController();
    final timeController = TextEditingController();
    final instructorController = TextEditingController();
    final roomController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedDay = 'Monday';

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Add Schedule', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedDay,
                        decoration: InputDecoration(
                          labelText: 'Day',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => selectedDay = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: subjectController,
                        hint: 'Subject',
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter subject' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: timeController,
                        hint: 'Time (e.g., 9:00 AM - 10:00 AM)',
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter time' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: instructorController,
                        hint: 'Instructor',
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter instructor' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: roomController,
                        hint: 'Room',
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter room' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final now = DateTime.now();
                      final schedule = ScheduleModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        day: selectedDay,
                        subject: subjectController.text.trim(),
                        time: timeController.text.trim(),
                        instructor: instructorController.text.trim(),
                        room: roomController.text.trim(),
                        createdAt: now,
                        updatedAt: now,
                      );
                      await this.context.read<ScheduleProvider>().createSchedule(schedule);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Schedule added successfully')),
                        );
                      }
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Schedule'),
          content: Text('Are you sure you want to delete this schedule?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await context.read<ScheduleProvider>().deleteSchedule(schedule.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
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
    final scheduleProvider = context.watch<ScheduleProvider>();
    final schedules = scheduleProvider.schedules;

    final Map<String, List<dynamic>> groupedSchedules = {};
    for (final schedule in schedules) {
      if (!groupedSchedules.containsKey(schedule.day)) {
        groupedSchedules[schedule.day] = [];
      }
      groupedSchedules[schedule.day]!.add(schedule);
    }

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final sortedDays = days.where((day) => groupedSchedules.containsKey(day)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Schedule', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: schedules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No schedule available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: sortedDays.length,
              itemBuilder: (context, dayIndex) {
                final day = sortedDays[dayIndex];
                final daySchedules = groupedSchedules[day]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        day,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...daySchedules.map((schedule) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomCard(
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      schedule.subject,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${schedule.time} • ${schedule.instructor} • ${schedule.room}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                onPressed: () => _showDeleteConfirmation(schedule),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleDialog,
        backgroundColor: theme.colorScheme.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Class', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
