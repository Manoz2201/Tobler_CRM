import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import './register_screen.dart';
import './forgot_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/developer_home_screen.dart';
import '../home/admin_home_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/sales_home_screen.dart';
import '../home/proposal_engineer_home_screen.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<String> _emailSuggestions = [];
  List<String> _allCachedEmails = [];

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
    _loadCachedEmails();
    _emailController.addListener(_onEmailChanged);
  }

  Future<void> _loadLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('last_email');
    if (lastEmail != null && lastEmail.isNotEmpty) {
      _emailController.text = lastEmail;
    }
  }

  Future<void> _saveLastEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_email', email);
  }

  Future<void> _loadCachedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allCachedEmails = prefs.getStringList('email_list') ?? [];
    });
  }

  void _onEmailChanged() {
    final input = _emailController.text.trim();
    if (input.length >= 2) {
      setState(() {
        _emailSuggestions = _allCachedEmails
            .where((e) => e.toLowerCase().startsWith(input.toLowerCase()))
            .toList();
      });
    } else {
      setState(() {
        _emailSuggestions = [];
      });
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String hashPassword(String password) {
    const salt = 'kumar';
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
                          Stack(
                            children: [
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              if (_emailSuggestions.isNotEmpty)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 60,
                                  child: Material(
                                    elevation: 2,
                                    borderRadius: BorderRadius.circular(8),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _emailSuggestions.length,
                                      itemBuilder: (context, index) {
                                        final suggestion =
                                            _emailSuggestions[index];
                                        return ListTile(
                                          title: Text(suggestion),
                                          onTap: () {
                                            setState(() {
                                              _emailController.text =
                                                  suggestion;
                                              _emailSuggestions = [];
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: _GradientButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final email = _emailController.text.trim();
                            await _saveLastEmail(email);
                            final hashedPassword = hashPassword(
                              _passwordController.text,
                            );
                            // Debug print for hash
                            // ignore: avoid_print
                            print('Login hash: $hashedPassword');
                            // Check users table
                            final userResult = await Supabase.instance.client
                                .from('users')
                                .select('id, verified, user_type')
                                .eq('email', email)
                                .eq('password_hash', hashedPassword)
                                .maybeSingle();
                            // Check dev_user table
                            final devUserResult = await Supabase.instance.client
                                .from('dev_user')
                                .select('id, verified, user_type')
                                .eq('email', email)
                                .eq('password_hash', hashedPassword)
                                .maybeSingle();
                            final result = userResult ?? devUserResult;
                            if (!context.mounted) return;
                            if (result != null && result['id'] != null) {
                              if (result['verified'] == true) {
                                String userType = result['user_type'] ?? '';
                                final session = Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentSession;
                                String sessionId = '';
                                if (session?.accessToken != null &&
                                    session!.accessToken.isNotEmpty) {
                                  sessionId = session.accessToken;
                                } else {
                                  sessionId = const Uuid().v4();
                                }
                                // Fetch device type and machine ID
                                String deviceType = 'unknown';
                                String machineId = 'unknown';
                                final deviceInfo = DeviceInfoPlugin();
                                if (kIsWeb) {
                                  deviceType = 'web';
                                  // Use userAgent as machineId for web
                                  machineId = const String.fromEnvironment(
                                    'USER_AGENT',
                                    defaultValue: 'web',
                                  );
                                } else if (Platform.isAndroid) {
                                  deviceType = 'android';
                                  final info = await deviceInfo.androidInfo;
                                  machineId = info.id;
                                } else if (Platform.isIOS) {
                                  deviceType = 'ios';
                                  final info = await deviceInfo.iosInfo;
                                  machineId =
                                      info.identifierForVendor ?? 'unknown';
                                } else if (Platform.isWindows) {
                                  deviceType = 'windows';
                                  final info = await deviceInfo.windowsInfo;
                                  machineId = info.deviceId;
                                } else if (Platform.isMacOS) {
                                  deviceType = 'macos';
                                  final info = await deviceInfo.macOsInfo;
                                  machineId = info.systemGUID ?? 'unknown';
                                }
                                if (!context.mounted) return;
                                if (userType == 'Developer') {
                                  await Supabase.instance.client
                                      .from('dev_user')
                                      .update({
                                        'session_id': sessionId,
                                        'session_active': true,
                                        'device_type': deviceType,
                                        'machine_id': machineId,
                                      })
                                      .eq('email', email);
                                  await saveSessionToCache(
                                    sessionId,
                                    true,
                                    result['id'].toString(),
                                    userType,
                                  );
                                  await setUserOnlineStatus(true);
                                  await updateUserOnlineStatusMCP(
                                    result['id'].toString(),
                                    true,
                                  );
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString('user_email', email);
                                  List<String> emailList =
                                      prefs.getStringList('email_list') ?? [];
                                  if (!emailList.contains(email)) {
                                    emailList.add(email);
                                    await prefs.setStringList(
                                      'email_list',
                                      emailList,
                                    );
                                  }
                                } else {
                                  await Supabase.instance.client
                                      .from('users')
                                      .update({
                                        'session_id': sessionId,
                                        'session_active': true,
                                        'device_type': deviceType,
                                        'machine_id': machineId,
                                      })
                                      .eq('email', email);
                                  await saveSessionToCache(
                                    sessionId,
                                    true,
                                    result['id'].toString(),
                                    userType,
                                  );
                                  await setUserOnlineStatus(true);
                                  await updateUserOnlineStatusMCP(
                                    result['id'].toString(),
                                    true,
                                  );
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString('user_email', email);
                                  List<String> emailList =
                                      prefs.getStringList('email_list') ?? [];
                                  if (!emailList.contains(email)) {
                                    emailList.add(email);
                                    await prefs.setStringList(
                                      'email_list',
                                      emailList,
                                    );
                                  }
                                }
                                if (userType == 'Sales') {
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SalesHomeScreen(
                                        currentUserType: userType,
                                        currentUserEmail: email,
                                        currentUserId: result['id'].toString(),
                                      ),
                                    ),
                                  );
                                } else if (userType == 'Proposal Engineer') {
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProposalHomeScreen(
                                        currentUserId: result['id'].toString(),
                                      ),
                                    ),
                                  );
                                } else {
                                  Widget homeScreen;
                                  if (userType == 'Developer') {
                                    homeScreen = const DeveloperHomeScreen();
                                  } else if (userType == 'Admin') {
                                    homeScreen = const AdminHomeScreen();
                                  } else {
                                    homeScreen = const Center(
                                      child: Text('User Home Removed'),
                                    );
                                  }
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => homeScreen,
                                    ),
                                  );
                                }
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please verify your account before logging in.',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Wrong Email or Password.'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sign Up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
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
