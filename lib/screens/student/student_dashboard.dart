import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/providers/theme_provider.dart';
import 'package:studentsupportsystem/screens/student/announcements_screen.dart';
import 'package:studentsupportsystem/screens/student/complaint_screen.dart';
import 'package:studentsupportsystem/screens/student/class_schedule_screen.dart';
import 'package:studentsupportsystem/screens/student/attendance_screen.dart';
import 'package:studentsupportsystem/screens/student/chatbot_screen.dart';
import 'package:studentsupportsystem/screens/student/profile_screen.dart';
import 'package:studentsupportsystem/screens/student/assignment_list.dart';
import 'package:studentsupportsystem/screens/student/lost_and_found_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

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
              theme.colorScheme.secondary.withValues(alpha: 0.05),
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
                            'Welcome Back 👋',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name ?? 'Student',
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
                              theme.colorScheme.secondary,
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
                            user?.name[0].toUpperCase() ?? 'S',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        theme.colorScheme.primary.withValues(alpha: 0.8),
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
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Portal',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Access all your academic resources',
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
                  'Quick Access',
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
                    _DashboardCard(
                      title: 'Announcements',
                      subtitle: 'Latest updates',
                      icon: Icons.campaign_rounded,
                      gradientColors: [theme.colorScheme.primary, const Color(0xFF8B5CF6)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
                      ),
                    ),
                    _DashboardCard(
                      title: 'Complaints',
                      subtitle: 'Submit issues',
                      icon: Icons.report_problem_rounded,
                      gradientColors: [theme.colorScheme.tertiary, const Color(0xFFF97316)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ComplaintScreen()),
                      ),
                    ),
                    _DashboardCard(
                      title: 'Attendance',
                      subtitle: 'View your percentage',
                      icon: Icons.bar_chart_rounded,
                      gradientColors: [theme.colorScheme.primary, const Color(0xFF0EA5E9)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                      ),
                    ),
                    _DashboardCard(
                      title: 'Timetable',
                      subtitle: 'Class schedule',
                      icon: Icons.calendar_today_rounded,
                      gradientColors: [theme.colorScheme.secondary, const Color(0xFF059669)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClassScheduleScreen()),
                      ),
                    ),
                    _DashboardCard(
                      title: 'AI Chatbot',
                      subtitle: 'Get help',
                      icon: Icons.smart_toy_rounded,
                      gradientColors: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatbotScreen()),
                      ),
                    ),
                    _DashboardCard(
                      title: 'Assignments',
                      subtitle: 'View tasks',
                      icon: Icons.assignment_rounded,
                      gradientColors: [
                        Colors.blue,
                        Colors.indigo
                      ],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentListScreen(),
                        ),
                      ),
                    ),


                    _DashboardCard(
                      title: 'Lost & Found',
                      subtitle: 'Find lost items',
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _DashboardCard({
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
