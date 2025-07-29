import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_info_screen.dart';

Future<void> clearLoginSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

class ProfilePage extends StatelessWidget {
  final VoidCallback? onLogout;
  final String? currentUserId;
  final String? currentUserEmail;
  final String? currentUserType;

  const ProfilePage({
    super.key,
    this.onLogout,
    this.currentUserId,
    this.currentUserEmail,
    this.currentUserType,
  });

  @override
  Widget build(BuildContext context) {
    // Get current user info if not provided
    final userId =
        currentUserId ?? Supabase.instance.client.auth.currentUser?.id ?? '';
    final userEmail = currentUserEmail ?? '';
    final userType = currentUserType ?? '';

    return ProfileInfoScreen(
      currentUserId: userId,
      currentUserEmail: userEmail,
      currentUserType: userType,
    );
  }
}
