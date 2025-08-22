import 'package:flutter/material.dart';

class NavigationUtils {
  static List<NavItem> getNavigationItemsForRole(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return [
          NavItem('Dashboard', Icons.dashboard),
          NavItem('Leads Management', Icons.leaderboard),
          NavItem('Offers', Icons.local_offer),
          NavItem('Sales Performance', Icons.trending_up),
          NavItem('User Management', Icons.group),
          NavItem('Role Management', Icons.security),
          NavItem('Profile', Icons.person),
          NavItem('Logout', Icons.logout),
        ];

      case 'sales':
        return [
          NavItem('Dashboard', Icons.dashboard),
          NavItem('Leads Management', Icons.leaderboard),
          NavItem('Offers', Icons.local_offer),
          NavItem('Customers', Icons.people),
          NavItem('Profile', Icons.person),
          NavItem('Logout', Icons.logout),
        ];

      case 'developer':
        return [
          NavItem('Dashboard', Icons.dashboard),
          NavItem('User Management', Icons.group),
          NavItem('Screen Management', Icons.desktop_windows),
          NavItem('Role Management', Icons.security),
          NavItem('Feature Configuration', Icons.tune),
          NavItem('AI', Icons.auto_awesome),
          NavItem('Settings', Icons.settings),
          NavItem('Analytics', Icons.bar_chart),
          NavItem('Profile', Icons.person),
          NavItem('Logout', Icons.logout),
        ];

      case 'proposal engineer':
        return [
          NavItem('Dashboard', Icons.dashboard),
          NavItem('Proposals', Icons.description),
          NavItem('Clients', Icons.people_outline),
          NavItem('Reports', Icons.bar_chart),
          NavItem('Chat', Icons.chat),
          NavItem('Profile', Icons.person),
          NavItem('Logout', Icons.logout),
        ];

      default:
        // Default navigation for unknown user types
        return [
          NavItem('Dashboard', Icons.dashboard),
          NavItem('Profile', Icons.person),
          NavItem('Logout', Icons.logout),
        ];
    }
  }

  static bool hasLeadsManagementAccess(String userType) {
    return ['admin', 'sales'].contains(userType.toLowerCase());
  }

  static bool hasUserManagementAccess(String userType) {
    return ['admin', 'developer'].contains(userType.toLowerCase());
  }

  static bool hasRoleManagementAccess(String userType) {
    return ['admin', 'developer'].contains(userType.toLowerCase());
  }
}

class NavItem {
  final String label;
  final IconData icon;

  const NavItem(this.label, this.icon);
}
