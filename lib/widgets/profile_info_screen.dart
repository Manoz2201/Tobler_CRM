import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../screens/auth/login_screen.dart';
import '../main.dart'
    show
        updateUserSessionActiveMCP,
        updateUserOnlineStatusMCP,
        updateUserOnlineStatusByEmailMCP,
        setUserOnlineStatus;
import 'profile_page.dart' show clearLoginSession;

class ProfileInfoScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserEmail;
  final String currentUserType;

  const ProfileInfoScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.currentUserType,
  });

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Step 1: Fetch active user_id from cache memory
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('user_id');
      final cachedSessionId = prefs.getString('session_id');
      final cachedSessionActive = prefs.getBool('session_active');

      debugPrint('[CACHE] Cached user_id: $cachedUserId');
      debugPrint('[CACHE] Cached session_id: $cachedSessionId');
      debugPrint('[CACHE] Cached session_active: $cachedSessionActive');

      if (cachedUserId == null) {
        debugPrint('[CACHE] No cached user_id found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final client = Supabase.instance.client;

      // Step 2: Look up user in Supabase users table
      var userData = await client
          .from('users')
          .select(
            'id, username, employee_code, email, user_type, session_id, session_active, is_user_online',
          )
          .eq('id', cachedUserId)
          .maybeSingle();

      debugPrint('[SUPABASE] Users table lookup result: $userData');

      // Step 3: If not found in users table, try dev_user table
      if (userData == null) {
        userData = await client
            .from('dev_user')
            .select(
              'id, username, employee_code, email, user_type, session_id, session_active, is_user_online',
            )
            .eq('id', cachedUserId)
            .maybeSingle();

        debugPrint('[SUPABASE] Dev_user table lookup result: $userData');
      }

      // Step 4: Validate if user is active and session matches
      if (userData != null) {
        final isActive = userData['session_active'] == true;
        final sessionMatches = userData['session_id'] == cachedSessionId;

        debugPrint(
          '[VALIDATION] User active: $isActive, Session matches: $sessionMatches',
        );

        if (isActive && sessionMatches) {
          // Step 5: Fetch device info from dev_user table if needed
          String? deviceType;
          if (userData['user_type'] == 'developer') {
            final devUserData = await client
                .from('dev_user')
                .select('device_type')
                .eq('id', cachedUserId)
                .maybeSingle();
            deviceType = devUserData?['device_type'];
          }

          // Step 6: Create final user data with only required profile columns
          final finalUserData = {
            'id': userData['id'],
            'username': userData['username'],
            'employee_code': userData['employee_code'],
            'email': userData['email'],
            'user_type': userData['user_type'],
            'is_user_online': userData['is_user_online'],
            'device_type': deviceType,
          };

          debugPrint('[PROFILE] Final user data: $finalUserData');

          setState(() {
            _userData = finalUserData;
            _isLoading = false;
          });
        } else {
          debugPrint('[VALIDATION] User not active or session mismatch');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        debugPrint('[SUPABASE] User not found in any table');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Here you would typically upload to Supabase Storage
        // For now, we'll just set the local path
        setState(() {
          _profileImageUrl = image.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile image')),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _profileImageUrl = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile image removed')));
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Checking for updates...'),
              ],
            ),
            content: Text('Please wait while we check for the latest version.'),
          );
        },
      );

      // Simulate update check (replace with actual update logic)
      await Future.delayed(Duration(seconds: 2));

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show update dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.system_update, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Update Available'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A new version of the CRM app is available!',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Version: 2.1.0',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Bug fixes and performance improvements\n• New export features\n• Enhanced security',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _performUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Update Now'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking for updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performUpdate() async {
    try {
      // Show update progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Updating...'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Downloading update...'),
                SizedBox(height: 12),
                LinearProgressIndicator(),
              ],
            ),
          );
        },
      );

      // Simulate update process
      await Future.delayed(Duration(seconds: 3));

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Update completed successfully! Please restart the app.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error performing update: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await setUserOnlineStatus(false);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    debugPrint('[LOGOUT] Logging out userId: $userId');

    if (userId != null) {
      await updateUserSessionActiveMCP(userId, false);
      await updateUserOnlineStatusMCP(userId, false);
    } else {
      debugPrint('[LOGOUT] userId is null, cannot update Supabase by id.');
    }

    // Update is_user_online by email
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    debugPrint('[LOGOUT] Logging out user_email: $email');
    if (email != null) {
      await updateUserOnlineStatusByEmailMCP(email, false);
    }

    await clearLoginSession();
    await Supabase.instance.client.auth.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: _profileImageUrl != null
              ? FileImage(File(_profileImageUrl!))
              : null,
          child: _profileImageUrl == null
              ? const Icon(Icons.person, size: 60, color: Colors.grey)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onPressed: _pickImage,
            ),
          ),
        ),
        if (_profileImageUrl != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                onPressed: _removeImage,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isOnlineStatus = false,
    bool isMobile = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6.0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 100 : 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: isOnlineStatus
                ? Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: value == 'true' ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value == 'true' ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: value == 'true' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ],
                  )
                : Text(
                    value.isEmpty ? 'N/A' : value,
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
              child: Column(
                children: [
                  // Header with Update and Logout Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Info',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _checkForUpdates,
                            icon: const Icon(
                              Icons.system_update,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Update',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          IconButton(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            tooltip: 'Logout',
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 20 : 30),

                  // Profile Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: Column(
                        children: [
                          // Profile Image Section
                          Center(
                            child: Column(
                              children: [
                                _buildProfileImage(),
                                SizedBox(height: isMobile ? 12 : 16),
                                Text(
                                  _userData?['username'] ?? 'Unknown User',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isMobile ? 6 : 8),
                                Text(
                                  _userData?['user_type'] ?? 'Unknown Type',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isMobile ? 24 : 32),

                          // User Info Section
                          const Divider(),
                          SizedBox(height: isMobile ? 12 : 16),

                          _buildInfoRow(
                            'Name',
                            _userData?['username'] ?? '',
                            isMobile: isMobile,
                          ),
                          _buildInfoRow(
                            'Employee Code',
                            _userData?['employee_code'] ?? '',
                            isMobile: isMobile,
                          ),
                          _buildInfoRow(
                            'Email ID',
                            _userData?['email'] ?? '',
                            isMobile: isMobile,
                          ),
                          _buildInfoRow(
                            'Device',
                            _userData?['device_type'] ?? '',
                            isMobile: isMobile,
                          ),
                          _buildInfoRow(
                            'User Type',
                            _userData?['user_type'] ?? '',
                            isMobile: isMobile,
                          ),
                          _buildInfoRow(
                            'Online Status',
                            _userData?['is_user_online']?.toString() ?? 'false',
                            isOnlineStatus: true,
                            isMobile: isMobile,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
