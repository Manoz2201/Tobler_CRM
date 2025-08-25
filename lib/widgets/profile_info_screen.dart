import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isCheckingUpdate = false;
  String? _updateMessage;
  bool _updateAvailable = false;

  // Profile editing functionality
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _employeeCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  bool _isProfileUpdateLoading = false;
  bool _isEditingProfile = false;

  // Settings functionality
  final TextEditingController _projectCodeController = TextEditingController();
  bool _isSettingsLoading = false;
  String? _currentProjectCode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrentProjectCode(); // Load project code settings
  }

  @override
  void dispose() {
    _projectCodeController.dispose(); // Dispose the project code controller
    _usernameController.dispose();
    _employeeCodeController.dispose();
    _emailController.dispose();
    _designationController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
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

      // Debug: Check if device_type field exists and has data
      try {
        debugPrint('[DEBUG] Checking users table structure and sample data...');
        final sampleUser = await client
            .from('users')
            .select('device_type, user_type')
            .limit(5)
            .maybeSingle();
        debugPrint('[DEBUG] Sample user data: $sampleUser');

        // Check if device_type field exists
        if (sampleUser != null) {
          debugPrint('[DEBUG] Available fields: ${sampleUser.keys.toList()}');
          debugPrint(
            '[DEBUG] Sample device_type: ${sampleUser['device_type']}',
          );
        }
      } catch (e) {
        debugPrint('[DEBUG] Error checking table structure: $e');
      }

      // Step 2: Look up user in Supabase users table
      debugPrint(
        '[SUPABASE] Looking up user with ID: $cachedUserId in users table',
      );
      debugPrint('[SUPABASE] User ID type: ${cachedUserId.runtimeType}');
      debugPrint('[SUPABASE] User ID length: ${cachedUserId.length}');

      var userData = await client
          .from('users')
          .select(
            'id, username, designation, mobile_number, employee_code, email, user_type, session_id, session_active, is_user_online, device_type',
          )
          .eq('id', cachedUserId)
          .maybeSingle();

      debugPrint('[SUPABASE] Users table lookup result: $userData');
      if (userData != null) {
        debugPrint(
          '[SUPABASE] Users table - device_type field: ${userData['device_type']}',
        );
        debugPrint(
          '[SUPABASE] Users table - all available fields: ${userData.keys.toList()}',
        );
      }

      // Step 3: If not found in users table, try dev_user table
      if (userData == null) {
        debugPrint(
          '[SUPABASE] User not found in users table, trying dev_user table',
        );
        userData = await client
            .from('dev_user')
            .select(
              'id, username, designation, mobile_number, employee_code, email, user_type, session_id, session_active, is_user_online, device_type',
            )
            .eq('id', cachedUserId)
            .maybeSingle();

        debugPrint('[SUPABASE] Dev_user table lookup result: $userData');
        if (userData != null) {
          debugPrint(
            '[SUPABASE] Dev_user table - device_type field: ${userData['device_type']}',
          );
          debugPrint(
            '[SUPABASE] Dev_user table - all available fields: ${userData.keys.toList()}',
          );
        }
      }

      // Step 4: Validate if user is active and session matches
      if (userData != null) {
        final isActive = userData['session_active'] == true;
        final sessionMatches = userData['session_id'] == cachedSessionId;

        debugPrint(
          '[VALIDATION] User active: $isActive, Session matches: $sessionMatches',
        );

        if (isActive && sessionMatches) {
          // Step 5: Get device type from the current user table
          String? deviceType;
          try {
            debugPrint('[DEVICE] Raw userData: $userData');
            debugPrint(
              '[DEVICE] userData device_type: ${userData['device_type']}',
            );
            debugPrint(
              '[DEVICE] userData device_type type: ${userData['device_type']?.runtimeType}',
            );

            // Get device type and handle various cases
            final rawDeviceType = userData['device_type'];
            if (rawDeviceType != null &&
                rawDeviceType.toString().isNotEmpty &&
                rawDeviceType.toString() != 'null') {
              deviceType = rawDeviceType.toString();
              debugPrint(
                '[DEVICE] Device type successfully extracted: $deviceType',
              );
            } else {
              debugPrint(
                '[DEVICE] Device type is null, empty, or "null" string',
              );
              deviceType = null;
            }

            debugPrint('[DEVICE] Final device type value: $deviceType');
          } catch (e) {
            debugPrint('[DEVICE] Error getting device type: $e');
            deviceType = null;
          }

          // Step 6: Create final user data with only required profile columns
          final finalUserData = {
            'id': userData['id'],
            'username': userData['username'],
            'designation': userData['designation'],
            'mobile_number': userData['mobile_number'],
            'employee_code': userData['employee_code'],
            'email': userData['email'],
            'user_type': userData['user_type'],
            'is_user_online': userData['is_user_online'],
            'device_type': deviceType ?? 'N/A',
          };

          debugPrint('[PROFILE] Final user data: $finalUserData');
          debugPrint(
            '[DEVICE] Final device type: ${finalUserData['device_type']}',
          );

          setState(() {
            _userData = finalUserData;
            _isLoading = false;
          });

          // Initialize profile editing controllers
          _usernameController.text = finalUserData['username'] ?? '';
          _designationController.text = finalUserData['designation'] ?? '';
          _mobileNumberController.text = finalUserData['mobile_number'] ?? '';
          _employeeCodeController.text = finalUserData['employee_code'] ?? '';
          _emailController.text = finalUserData['email'] ?? '';
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

  // Load current project code from settings
  Future<void> _loadCurrentProjectCode() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('settings')
          .select('project_code')
          .limit(1)
          .single();

      setState(() {
        _currentProjectCode = response['project_code'];
        _projectCodeController.text = _currentProjectCode ?? '';
      });
    } catch (e) {
      // Handle error or no existing project code
      setState(() {
        _currentProjectCode = null;
        _projectCodeController.text = '';
      });
    }
  }

  // Save project code to settings
  Future<void> _saveProjectCode() async {
    if (_projectCodeController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please enter a project code')));
      }
      return;
    }

    setState(() {
      _isSettingsLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final baseCode = _projectCodeController.text.trim();

      // Get the next sequence number
      final response = await client
          .from('settings')
          .select('project_code')
          .limit(1)
          .maybeSingle();

      int nextSequence = 1;
      if (response != null && response['project_code'] != null) {
        final currentCode = response['project_code'] as String;
        final parts = currentCode.split('-');
        if (parts.length > 1) {
          final lastPart = int.tryParse(parts.last) ?? 0;
          nextSequence = lastPart + 1;
        }
      }

      final newProjectCode =
          '$baseCode-${nextSequence.toString().padLeft(5, '0')}';

      // Update or insert the project code
      await client.from('settings').upsert({'project_code': newProjectCode});

      if (mounted) {
        setState(() {
          _currentProjectCode = newProjectCode;
          _isSettingsLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project code saved: $newProjectCode')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSettingsLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving project code: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateMessage = null;
      _updateAvailable = false;
    });

    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Get device type
      String deviceType = 'unknown';
      if (Platform.isAndroid) {
        deviceType = 'android';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      } else if (Platform.isWindows) {
        deviceType = 'windows';
      } else if (Platform.isMacOS) {
        deviceType = 'macos';
      } else if (Platform.isLinux) {
        deviceType = 'linux';
      }

      // Check GitHub releases for latest version
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/aaryesha17/AluminumFormworkCRM/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        final latestVersion =
            releaseData['tag_name']?.replaceAll('v', '') ?? '';
        final releaseAssets = releaseData['assets'] as List<dynamic>? ?? [];

        // Find asset for current device type
        Map<String, dynamic>? deviceAsset;
        String? downloadUrl;

        for (final asset in releaseAssets) {
          final assetName = asset['name'] as String? ?? '';
          if (deviceType == 'android' && assetName.endsWith('.apk')) {
            deviceAsset = asset;
            downloadUrl = asset['browser_download_url'];
            break;
          } else if (deviceType == 'windows' && assetName.endsWith('.exe')) {
            deviceAsset = asset;
            downloadUrl = asset['browser_download_url'];
            break;
          } else if (deviceType == 'ios' && assetName.endsWith('.ipa')) {
            deviceAsset = asset;
            downloadUrl = asset['browser_download_url'];
            break;
          }
        }

        // Compare versions
        if (_compareVersions(latestVersion, currentVersion) > 0) {
          setState(() {
            _updateAvailable = true;
            _updateMessage = 'New version $latestVersion available!';
          });

          // Show update dialog
          _showUpdateDialog(latestVersion, downloadUrl, deviceAsset);
        } else {
          setState(() {
            _updateMessage = 'You have the latest version ($currentVersion)';
          });
        }
      } else {
        setState(() {
          _updateMessage = 'Failed to check for updates. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _updateMessage = 'Error checking for updates: $e';
      });
    } finally {
      setState(() {
        _isCheckingUpdate = false;
      });
    }
  }

  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < math.max(v1Parts.length, v2Parts.length); i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1 > v2) return 1;
      if (v1 < v2) return -1;
    }
    return 0;
  }

  void _showUpdateDialog(
    String latestVersion,
    String? downloadUrl,
    Map<String, dynamic>? asset,
  ) {
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
              Text('A new version ($latestVersion) is available!'),
              SizedBox(height: 16),
              if (asset != null) ...[
                Text('File: ${asset['name']}'),
                Text('Size: ${_formatFileSize(asset['size'])}'),
                SizedBox(height: 8),
              ],
              Text('Would you like to download and install the update?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (downloadUrl != null) {
                  _downloadAndInstall(downloadUrl);
                }
              },
              child: Text('Download & Install'),
            ),
          ],
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _downloadAndInstall(String downloadUrl) async {
    try {
      // Show download progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Downloading Update'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading the latest version...'),
              ],
            ),
          );
        },
      );

      // Launch download URL
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open download link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading update: $e'),
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

  String _getDeviceTypeDisplay() {
    final deviceType = _userData?['device_type'];
    if (deviceType == null || deviceType.toString().isEmpty) {
      return 'N/A';
    }
    return deviceType.toString();
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: const Color(
            0xFFF3E5F5,
          ), // Light purple background for profile image
          backgroundImage: _profileImageUrl != null
              ? FileImage(File(_profileImageUrl!))
              : null,
          child: _profileImageUrl == null
              ? Icon(
                  Icons.person,
                  size: 60,
                  color: const Color(
                    0xFF7B1FA2,
                  ), // Purple icon matching app theme
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(
                0xFF2196F3,
              ), // Blue background matching app theme
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
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8.0 : 10.0),
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
                color: const Color(
                  0xFF424242,
                ), // Dark grey text matching app theme
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
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: const Color(
                        0xFF424242,
                      ), // Dark grey text matching app theme
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(
    String label,
    String value,
    TextEditingController controller, {
    bool isMobile = false,
    bool isEditing = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8.0 : 10.0),
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
                color: const Color(
                  0xFF424242,
                ), // Dark grey text matching app theme
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF2196F3),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  )
                : Text(
                    value.isEmpty ? 'N/A' : value,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: const Color(
                        0xFF424242,
                      ), // Dark grey text matching app theme
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Build Profile Card with reduced padding
  Widget _buildProfileCard(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          setState(() {
            _isEditingProfile = !_isEditingProfile;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // White background matching navigation bar
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
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
                        color: const Color(
                          0xFF424242,
                        ), // Dark grey text matching app theme
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      _userData?['user_type'] ?? 'Unknown Type',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: const Color(
                          0xFF424242,
                        ), // Dark grey text matching app theme
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 20 : 24),
              // User Info Section
              const Divider(color: Color(0xFFE0E0E0)),
              SizedBox(height: isMobile ? 12 : 16),

              _buildEditableInfoRow(
                'Name',
                _userData?['username'] ?? '',
                _usernameController,
                isMobile: isMobile,
                isEditing: _isEditingProfile,
              ),
              _buildEditableInfoRow(
                'Designation',
                _userData?['designation'] ?? '',
                _designationController,
                isMobile: isMobile,
                isEditing: _isEditingProfile,
              ),
              _buildEditableInfoRow(
                'Employee Code',
                _userData?['employee_code'] ?? '',
                _employeeCodeController,
                isMobile: isMobile,
                isEditing: _isEditingProfile,
              ),
              _buildEditableInfoRow(
                'Email ID',
                _userData?['email'] ?? '',
                _emailController,
                isMobile: isMobile,
                isEditing: _isEditingProfile,
              ),
              _buildEditableInfoRow(
                'Mobile Number',
                _userData?['mobile_number'] ?? '',
                _mobileNumberController,
                isMobile: isMobile,
                isEditing: _isEditingProfile,
              ),
              _buildInfoRow(
                'User Type',
                _userData?['user_type'] ?? '',
                isMobile: isMobile,
              ),
              _buildInfoRow(
                'Device',
                _getDeviceTypeDisplay(),
                isMobile: isMobile,
              ),
              _buildInfoRow(
                'Online Status',
                _userData?['is_user_online']?.toString() ?? 'false',
                isOnlineStatus: true,
                isMobile: isMobile,
              ),

              // Action buttons (only show when editing)
              if (_isEditingProfile) ...[
                SizedBox(height: isMobile ? 16 : 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isProfileUpdateLoading
                          ? null
                          : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: _isProfileUpdateLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditingProfile = false;
                          // Reset controllers to original values
                          _usernameController.text =
                              _userData?['username'] ?? '';
                          _designationController.text =
                              _userData?['designation'] ?? '';
                          _mobileNumberController.text =
                              _userData?['mobile_number'] ?? '';
                          _employeeCodeController.text =
                              _userData?['employee_code'] ?? '';
                          _emailController.text = _userData?['email'] ?? '';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF44336),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Build Settings Card with Project Code Configuration
  Widget _buildSettingsCard(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // White background matching navigation bar
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Code Configuration',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(
                  0xFF424242,
                ), // Dark grey text matching app theme
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Set the base project code. The system will automatically generate sequential codes like "Tobler-00001", "Tobler-00002", etc.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(
                  0xFF424242,
                ), // Dark grey text matching app theme
                height: 1.4,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _projectCodeController,
              decoration: InputDecoration(
                labelText: 'Base Project Code',
                hintText: 'e.g., Tobler',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: const Color(0xFF2196F3),
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(Icons.code, color: const Color(0xFF424242)),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            if (_currentProjectCode != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), // Light blue background
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2196F3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: const Color(0xFF2196F3), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Current: $_currentProjectCode',
                        style: TextStyle(
                          color: const Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSettingsLoading ? null : _saveProjectCode,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(
                    0xFF2196F3,
                  ), // Blue button matching app theme
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isSettingsLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Save Project Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update profile information
  Future<void> _updateProfile() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    setState(() {
      _isProfileUpdateLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      // Get the active user ID from loaded user data or cached preferences
      String userId = '';

      if (_userData != null && _userData!['id'] != null) {
        userId = _userData!['id'].toString();
        debugPrint('[PROFILE_UPDATE] Using user ID from loaded data: $userId');
      } else {
        // Fallback to cached user ID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final cachedUserId = prefs.getString('user_id');
        if (cachedUserId != null && cachedUserId.isNotEmpty) {
          userId = cachedUserId;
          debugPrint('[PROFILE_UPDATE] Using cached user ID: $userId');
        } else {
          throw Exception('User ID not found. Please try logging in again.');
        }
      }

      debugPrint('[PROFILE_UPDATE] Updating profile for user ID: $userId');
      debugPrint('[PROFILE_UPDATE] New values:');
      debugPrint(
        '[PROFILE_UPDATE] - Name (username): ${_usernameController.text.trim()}',
      );
      debugPrint(
        '[PROFILE_UPDATE] - Designation: ${_designationController.text.trim()}',
      );
      debugPrint(
        '[PROFILE_UPDATE] - Mobile Number: ${_mobileNumberController.text.trim()}',
      );
      debugPrint(
        '[PROFILE_UPDATE] - Employee Code (employee_code): ${_employeeCodeController.text.trim()}',
      );
      debugPrint(
        '[PROFILE_UPDATE] - Email ID (email): ${_emailController.text.trim()}',
      );

      // First try to update in the users table
      debugPrint('[PROFILE_UPDATE] Attempting to update users table...');

      try {
        final response = await client
            .from('users')
            .update({
              'username': _usernameController.text
                  .trim(), // Override Name value in username column
              'designation': _designationController.text.trim(),
              'mobile_number': _mobileNumberController.text.trim(),
              'employee_code': _employeeCodeController.text
                  .trim(), // Override Employee Code value in employee_code column
              'email': _emailController.text
                  .trim(), // Override Email ID value in email column
            })
            .eq('id', userId); // Use the specific user ID

        debugPrint(
          '[PROFILE_UPDATE] Users table update completed successfully',
        );
        debugPrint('[PROFILE_UPDATE] Response: $response');
      } catch (usersError) {
        debugPrint('[PROFILE_UPDATE] Users table update failed: $usersError');
        debugPrint('[PROFILE_UPDATE] Trying dev_user table as fallback...');

        // Try dev_user table if users table fails
        try {
          final devResponse = await client
              .from('dev_user')
              .update({
                'username': _usernameController.text
                    .trim(), // Override Name value in username column
                'designation': _designationController.text.trim(),
                'mobile_number': _mobileNumberController.text.trim(),
                'employee_code': _employeeCodeController.text
                    .trim(), // Override Employee Code value in employee_code column
                'email': _emailController.text
                    .trim(), // Override Email ID value in email column
              })
              .eq('id', userId); // Use the specific user ID

          debugPrint(
            '[PROFILE_UPDATE] Dev_user table update completed successfully',
          );
          debugPrint('[PROFILE_UPDATE] Dev response: $devResponse');
        } catch (devError) {
          debugPrint(
            '[PROFILE_UPDATE] Dev_user table update also failed: $devError',
          );
          throw Exception(
            'Failed to update profile in both tables. Users error: $usersError, Dev error: $devError',
          );
        }
      }

      // Verify the update by fetching the updated data
      final verificationResponse = await client
          .from('users')
          .select('username, designation, mobile_number, employee_code, email')
          .eq('id', userId)
          .maybeSingle();

      if (verificationResponse != null) {
        debugPrint(
          '[PROFILE_UPDATE] Verification - Updated values in database:',
        );
        debugPrint(
          '[PROFILE_UPDATE] - username: ${verificationResponse['username']}',
        );
        debugPrint(
          '[PROFILE_UPDATE] - designation: ${verificationResponse['designation']}',
        );
        debugPrint(
          '[PROFILE_UPDATE] - mobile_number: ${verificationResponse['mobile_number']}',
        );
        debugPrint(
          '[PROFILE_UPDATE] - employee_code: ${verificationResponse['employee_code']}',
        );
        debugPrint(
          '[PROFILE_UPDATE] - email: ${verificationResponse['email']}',
        );
      }

      // Update local state
      setState(() {
        _userData = {
          ..._userData!,
          'username': _usernameController.text.trim(),
          'designation': _designationController.text.trim(),
          'mobile_number': _mobileNumberController.text.trim(),
          'employee_code': _employeeCodeController.text.trim(),
          'email': _emailController.text.trim(),
        };
        _isProfileUpdateLoading = false;
        _isEditingProfile = false; // Exit editing mode
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully in database'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('[PROFILE_UPDATE] Error updating profile: $e');
      setState(() {
        _isProfileUpdateLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(
        0xFFFAFAFA,
      ), // Light grey background matching app theme
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
                          color: const Color(
                            0xFF424242,
                          ), // Dark grey text matching app theme
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isCheckingUpdate
                                ? null
                                : _checkForUpdates,
                            icon: _isCheckingUpdate
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.system_update,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _isCheckingUpdate ? 'Checking...' : 'Update',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF2196F3,
                              ), // Blue button matching app theme
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
                  // Update status message
                  if (_updateMessage != null)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _updateAvailable
                            ? const Color(0xFFE8F5E8) // Light green background
                            : const Color(0xFFE3F2FD), // Light blue background
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _updateAvailable
                              ? const Color(0xFF4CAF50) // Green border
                              : const Color(0xFF2196F3), // Blue border
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _updateAvailable ? Icons.check_circle : Icons.info,
                            color: _updateAvailable
                                ? const Color(0xFF4CAF50) // Green icon
                                : const Color(0xFF2196F3), // Blue icon
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _updateMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color: _updateAvailable
                                    ? const Color(0xFF2E7D32) // Dark green text
                                    : const Color(0xFF1976D2), // Dark blue text
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: isMobile ? 20 : 30),

                  // Profile and Settings Cards Row
                  if (isMobile)
                    // Mobile: Stack cards vertically
                    Column(
                      children: [
                        _buildProfileCard(isMobile),
                        SizedBox(height: 16),
                        _buildSettingsCard(isMobile),
                      ],
                    )
                  else
                    // Desktop: Side by side cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildProfileCard(isMobile)),
                        SizedBox(width: 16),
                        Expanded(child: _buildSettingsCard(isMobile)),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
