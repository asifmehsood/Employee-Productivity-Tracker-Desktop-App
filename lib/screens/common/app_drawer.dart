/// App Drawer
/// Reusable navigation drawer with current page highlighting
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard_screen.dart';
import '../calendar_screen.dart';
import '../profile_screen.dart';
import '../settings_screen.dart';
import '../sign_in_screen.dart';

enum DrawerPage {
  taskCreation,
  dashboard,
  workCalendar,
  profile,
  settings,
}

class AppDrawer extends StatelessWidget {
  final DrawerPage currentPage;

  const AppDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final greenColor = const Color(0xFF1c4d2c);
    
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      greenColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: greenColor,
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authProvider.employeeName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.home,
                title: 'Work Session',
                isSelected: currentPage == DrawerPage.taskCreation,
                onTap: () {
                  Navigator.pop(context);
                  if (currentPage != DrawerPage.taskCreation) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                greenColor: greenColor,
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.dashboard,
                title: 'Dashboard',
                isSelected: currentPage == DrawerPage.dashboard,
                onTap: () {
                  Navigator.pop(context);
                  if (currentPage != DrawerPage.dashboard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  }
                },
                greenColor: greenColor,
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.calendar_month,
                title: 'Work Calendar',
                isSelected: currentPage == DrawerPage.workCalendar,
                onTap: () {
                  Navigator.pop(context);
                  if (currentPage != DrawerPage.workCalendar) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  }
                },
                greenColor: greenColor,
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.person,
                title: 'Profile',
                isSelected: currentPage == DrawerPage.profile,
                onTap: () {
                  Navigator.pop(context);
                  if (currentPage != DrawerPage.profile) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }
                },
                greenColor: greenColor,
              ),
              const Divider(),
              _buildDrawerItem(
                context: context,
                icon: Icons.settings,
                title: 'Settings',
                isSelected: currentPage == DrawerPage.settings,
                onTap: () {
                  Navigator.pop(context);
                  if (currentPage != DrawerPage.settings) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  }
                },
                greenColor: greenColor,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true && context.mounted) {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color greenColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  greenColor.withOpacity(0.3),
                  greenColor.withOpacity(0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: greenColor.withOpacity(0.5), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        selected: isSelected,
      ),
    );
  }
}
