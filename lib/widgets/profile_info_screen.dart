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

  // Build Profile Card with reduced padding
  Widget _buildProfileCard(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0), // Reduced padding
        child: Column(
          children: [
            // Profile Image Section
            Center(
              child: Column(
                children: [
                  _buildProfileImage(),
                  SizedBox(height: isMobile ? 8 : 12), // Reduced spacing
                  Text(
                    _userData?['username'] ?? 'Unknown User',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22, // Slightly reduced font
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4), // Reduced spacing
                  Text(
                    _userData?['user_type'] ?? 'Unknown Type',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14, // Slightly reduced font
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20), // Reduced spacing
            // User Info Section
            const Divider(),
            SizedBox(height: isMobile ? 8 : 12), // Reduced spacing

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
    );
  }

  // Build Settings Card with Project Code Configuration
  Widget _buildSettingsCard(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Code Configuration',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8), // Reduced spacing
            Text(
              'Set the base project code. The system will automatically generate sequential codes like "Tobler-00001", "Tobler-00002", etc.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16), // Reduced spacing
            TextField(
              controller: _projectCodeController,
              decoration: InputDecoration(
                labelText: 'Base Project Code',
                hintText: 'e.g., Tobler',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.code),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ), // Reduced padding
              ),
            ),
            SizedBox(height: 12), // Reduced spacing
            if (_currentProjectCode != null)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current: $_currentProjectCode',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 12), // Reduced spacing
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSettingsLoading ? null : _saveProjectCode,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: 12,
                  ), // Reduced padding
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSettingsLoading
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
                    : Text('Save Project Code'),
              ),
            ),
          ],
        ),
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
                  // Update status message
                  if (_updateMessage != null)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _updateAvailable
                            ? Colors.green[50]
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _updateAvailable
                              ? Colors.green[200]!
                              : Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _updateAvailable ? Icons.check_circle : Icons.info,
                            color: _updateAvailable
                                ? Colors.green
                                : Colors.blue,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _updateMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _updateAvailable
                                    ? Colors.green[800]
                                    : Colors.blue[800],
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
