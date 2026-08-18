import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/screens/student/student_dashboard.dart';
import 'package:studentsupportsystem/screens/admin/admin_dashboard.dart';
import 'package:studentsupportsystem/widgets/custom_button.dart';
import 'package:studentsupportsystem/widgets/custom_textfield.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _enrollmentController = TextEditingController(); // NEW
  String _selectedRole = 'student';
  String _selectedClassGroup = 'IT Sem-6 Div A';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const classGroups = [
    'IT Sem-2 Div A',
    'IT Sem-2 Div B',
    'IT Sem-4 Div A',
    'IT Sem-4 Div B',
    'IT Sem-6 Div A',
    'IT Sem-6 Div B',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _enrollmentController.dispose(); // NEW
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        classGroup: _selectedRole == 'student' ? _selectedClassGroup : '',
        enrollmentNumber: _selectedRole == 'student' // NEW
            ? _enrollmentController.text.trim()
            : '',
      );

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));

      final user = authProvider.currentUser;
      if (user != null) {
        if (!mounted) return;

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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
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
                  Text(
                    'Class Group',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedClassGroup,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: classGroups
                          .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedClassGroup = value ?? _selectedClassGroup),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // NEW: Enrollment Number field
                  CustomTextField(
                    controller: _enrollmentController,
                    label: 'Enrollment Number',
                    hint: 'Enter your enrollment number',
                    prefixIcon: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                    validator: (value) {
                      if (_selectedRole == 'student' && (value == null || value.isEmpty)) {
                        return 'Please enter your enrollment number';
                      }
                      return null;
                    },
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