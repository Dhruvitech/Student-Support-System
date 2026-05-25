import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/screens/admin/admin_dashboard.dart';
import 'package:studentsupportsystem/screens/student/student_dashboard.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';
import 'package:studentsupportsystem/widgets/custom_button.dart';
import 'package:studentsupportsystem/widgets/custom_textfield.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'student';
  
  // Sorted branches by subject/branch code
  final Map<String, Map<String, String>> _branches = {
    '02': {'name': 'Automobile Engineering', 'abbreviation': 'AUTO'},
    '03': {'name': 'Biomedical Engineering', 'abbreviation': 'BIOMED'},
    '05': {'name': 'Chemical Engineering', 'abbreviation': 'CHEM'},
    '06': {'name': 'Civil Engineering', 'abbreviation': 'CIVIL'},
    '07': {'name': 'Computer Engineering', 'abbreviation': 'CSE'},
    '09': {'name': 'Electrical Engineering', 'abbreviation': 'ELEC'},
    '11': {'name': 'Electronics and Communication Engineering', 'abbreviation': 'EC'},
    '13': {'name': 'Environmental Engineering', 'abbreviation': 'ENV'},
    '16': {'name': 'Information Technology', 'abbreviation': 'IT'},
    '17': {'name': 'Instrumentation & Control Engineering', 'abbreviation': 'IC'},
    '19': {'name': 'Mechanical Engineering', 'abbreviation': 'MECH'},
    '23': {'name': 'Plastic Technology', 'abbreviation': 'PLASTIC'},
    '29': {'name': 'Textile Technology', 'abbreviation': 'TEXTILE'},
    '40': {'name': 'Rubber Technology', 'abbreviation': 'RUBBER'},
    '48': {'name': 'Robotics and Automation', 'abbreviation': 'ROBOTICS'},
    '52': {'name': 'Artificial Intelligence and Machine Learning', 'abbreviation': 'AIML'},
  };

  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> _divisions = ['A', 'B', 'C', 'D'];

  String _selectedBranchCode = '16';
  String _selectedSemester = '6';
  String _selectedDivision = 'A';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _firestoreService.ensureDefaultClassGroups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _enrollmentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRole == 'student' && _enrollmentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an enrollment number.')),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      String constructedClassGroup = '';
      String enrollmentNumber = '';

      if (_selectedRole == 'student') {
        final selectedBranch = _branches[_selectedBranchCode]!;
        final branchAbbr = selectedBranch['abbreviation']!;
        constructedClassGroup = '$branchAbbr Sem-$_selectedSemester Div $_selectedDivision';
        enrollmentNumber = _enrollmentController.text.trim();

        // Ensure class group exists in Firestore dynamically
        await _firestoreService.createClassGroup(
          branch: branchAbbr,
          semester: int.parse(_selectedSemester),
          division: _selectedDivision,
        );
      }

      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        classGroup: constructedClassGroup,
        enrollmentNumber: enrollmentNumber,
      );

      if (!mounted) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final user = authProvider.currentUser;
      if (user != null) {
        if (!mounted) {
          return;
        }

        if (user.role == 'student') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        }
      } else {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Role',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleOption(
                        title: 'Student',
                        icon: Icons.school,
                        isSelected: _selectedRole == 'student',
                        onTap: () => setState(() => _selectedRole = 'student'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _RoleOption(
                        title: 'Admin',
                        icon: Icons.admin_panel_settings,
                        isSelected: _selectedRole == 'admin',
                        onTap: () => setState(() => _selectedRole = 'admin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_selectedRole == 'student') ...[
                  CustomTextField(
                    controller: _enrollmentController,
                    label: 'Enrollment Number',
                    hint: 'Enter your GTU enrollment number',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                    validator: (value) {
                      if (_selectedRole == 'student') {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your enrollment number';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a valid enrollment number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Branch',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedBranchCode,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: _branches.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text('${entry.value['name']} (${entry.key})'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedBranchCode = value ?? '16');
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semester',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedSemester,
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                items: _semesters
                                    .map((sem) => DropdownMenuItem(
                                          value: sem,
                                          child: Text('Sem-$sem'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedSemester = value ?? '6');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Division',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedDivision,
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                items: _divisions
                                    .map((div) => DropdownMenuItem(
                                          value: div,
                                          child: Text('Div $div'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedDivision = value ?? 'A');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Sign Up',
                  onPressed: _signup,
                  isLoading: authProvider.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
