import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import './login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers for the form fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _employeeCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _employeeCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Add this function to hash the password with salt
  String hashPassword(String password) {
    const salt = 'kumar';
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate a unique 8-character uppercase verification code
  String generateVerificationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rand = Random.secure();
    return List.generate(
      8,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Future<void> _showVerificationDialog(String email, String userType) async {
    final codeController = TextEditingController();
    bool verifying = false;
    String? errorText;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Verification Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      errorText: errorText,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: verifying ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: verifying
                      ? null
                      : () async {
                          setState(() => verifying = true);
                          final code = codeController.text.trim().toUpperCase();
                          final table = userType == 'Developer'
                              ? 'dev_user'
                              : 'users';
                          final result = await Supabase.instance.client
                              .from(table)
                              .select('id')
                              .eq('email', email)
                              .eq('verification_code', code)
                              .maybeSingle();
                          if (result != null && result['id'] != null) {
                            await Supabase.instance.client
                                .from(table)
                                .update({'verified': true})
                                .eq('id', result['id']);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification successful!'),
                              ),
                            );
                          } else {
                            setState(() {
                              errorText = 'Invalid code. Please try again.';
                              verifying = false;
                            });
                          }
                        },
                  child: verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey[100]),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 450,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.08 * 255).toInt()),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and title
                    Column(
                      children: [
                        Image.asset('assets/Tobler_logo.png', height: 80),
                        const SizedBox(height: 24),
                      ],
                    ),
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _usernameController,
                            label: 'User Name',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _employeeCodeController,
                            label: 'Employee Code',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      child: _GradientButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final email = _emailController.text.trim();
                            final username = _usernameController.text.trim();
                            // 1. Check invitation table for this email to get user_type
                            final invitation = await Supabase.instance.client
                                .from('invitation')
                                .select('user_type')
                                .eq('email', email)
                                .maybeSingle();
                            String? userType;
                            if (invitation != null &&
                                invitation['user_type'] != null) {
                              // If invitation exists, use its user_type
                              userType = invitation['user_type'];
                            } else if (username.endsWith('__dev')) {
                              // (Fallback) If username ends with __dev, treat as Developer
                              userType = 'Developer';
                            }
                            if (!context.mounted) return;
                            if (userType == null) {
                              // No invitation and not a dev fallback: not authorized
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'You are not authorized to sign up.',
                                  ),
                                ),
                              );
                              return;
                            }
                            // 2. Check if user already exists in users or dev_user tables
                            final userExists = await Supabase.instance.client
                                .from('users')
                                .select('verified')
                                .eq('email', email)
                                .maybeSingle();
                            final devUserExists = await Supabase.instance.client
                                .from('dev_user')
                                .select('verified')
                                .eq('email', email)
                                .maybeSingle();
                            if (!context.mounted) return;
                            if ((userExists != null &&
                                    userExists['verified'] == true) ||
                                (devUserExists != null &&
                                    devUserExists['verified'] == true)) {
                              // User already exists and is verified
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User already exists.'),
                                ),
                              );
                              return;
                            }
                            if ((userExists != null &&
                                    userExists['verified'] == false) ||
                                (devUserExists != null &&
                                    devUserExists['verified'] == false)) {
                              // User exists but not verified: show verification dialog
                              await _showVerificationDialog(email, userType);
                              return;
                            }
                            // 3. If user does not exist, insert into correct table based on user_type
                            final hashedPassword = hashPassword(
                              _passwordController.text,
                            );
                            final verificationCode = generateVerificationCode();
                            try {
                              if (userType == 'Developer') {
                                // Insert new developer user
                                await Supabase.instance.client
                                    .from('dev_user')
                                    .insert({
                                      'username': username,
                                      'employee_code': _employeeCodeController
                                          .text
                                          .trim(),
                                      'email': email,
                                      'password_hash': hashedPassword,
                                      'verification_code': verificationCode,
                                      'verified': false,
                                      'user_type': userType,
                                    });
                              } else {
                                // Insert new regular user
                                await Supabase.instance.client
                                    .from('users')
                                    .insert({
                                      'username': username,
                                      'employee_code': _employeeCodeController
                                          .text
                                          .trim(),
                                      'email': email,
                                      'password_hash': hashedPassword,
                                      'verification_code': verificationCode,
                                      'user_type': userType,
                                    });
                              }
                              if (!context.mounted) return;
                              // Show verification dialog after successful insert
                              await _showVerificationDialog(email, userType);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Registration failed: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  const _GradientButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
