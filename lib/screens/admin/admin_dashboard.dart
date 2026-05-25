import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/providers/theme_provider.dart';
import 'package:studentsupportsystem/screens/admin/announcements_admin_screen.dart';
import 'package:studentsupportsystem/screens/admin/complaints_admin_screen.dart';
import 'package:studentsupportsystem/screens/admin/attendance_class_screen.dart';
import 'package:studentsupportsystem/screens/admin/class_schedule_admin_screen.dart';
import 'package:studentsupportsystem/screens/admin/manage_students_screen.dart';
import 'package:studentsupportsystem/screens/student/profile_screen.dart';
import 'package:studentsupportsystem/screens/admin/create_assignment.dart';
import 'package:studentsupportsystem/screens/admin/lost_and_found_admin_screen.dart';

import 'package:studentsupportsystem/services/firestore_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.tertiary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Portal 🛡️',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name ?? 'Admin',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              const Color(0xFF8B5CF6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            user?.name[0].toUpperCase() ?? 'A',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        context.watch<ThemeProvider>().themeMode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                      tooltip: 'Toggle theme',
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        const Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Control Center',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage all system operations',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Management Tools',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    _AdminCard(
                      title: 'Announcements',
                      subtitle: 'Post updates',
                      icon: Icons.campaign_rounded,
                      gradientColors: [
                        theme.colorScheme.primary,
                        const Color(0xFF8B5CF6)
                      ],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnnouncementsAdminScreen(),
                        ),
                      ),
                    ),
                    _AdminCard(
                      title: 'Complaints',
                      subtitle: 'Handle issues',
                      icon: Icons.report_problem_rounded,
                      gradientColors: [
                        theme.colorScheme.tertiary,
                        const Color(0xFFF97316)
                      ],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ComplaintsAdminScreen(),
                        ),
                      ),
                    ),
                    _AdminCard(
                      title: 'Attendance',
                      subtitle: 'Take daily attendance',
                      icon: Icons.checklist_rtl,
                      gradientColors: [
                        theme.colorScheme.primary,
                        const Color(0xFF0EA5E9)
                      ],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceClassScreen(),
                        ),
                      ),
                    ),
                    _AdminCard(
                      title: 'Schedule',
                      subtitle: 'Manage classes',
                      icon: Icons.calendar_today_rounded,
                      gradientColors: [
                        theme.colorScheme.secondary,
                        const Color(0xFF059669)
                      ],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClassScheduleAdminScreen(),
                        ),
                      ),
                    ),
                    _AdminCard(
                      title: 'Students',
                      subtitle: 'User management',
                      icon: Icons.people_rounded,
                      gradientColors: [
                        const Color(0xFFEC4899),
                        const Color(0xFFDB2777)
                      ],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageStudentsScreen(),
                        ),
                      ),
                    ),

                    // ✅ ADDED: Assignments
                    _AdminCard(
                      title: 'Assignments',
                      subtitle: 'Create & manage',
                      icon: Icons.assignment_rounded,
                      gradientColors: [Colors.blue, Colors.indigo],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateAssignmentScreen(),
                        ),
                      ),
                    ),



                    _AdminCard(
                      title: 'Lost & Found',
                      subtitle: 'Manage items',
                      icon: Icons.search_rounded,
                      gradientColors: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
                      onTap: () => Navigator.push(
                       context,
                       MaterialPageRoute(builder: (_) => LostAndFoundAdminScreen()),
                      ),
                    ), 
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}