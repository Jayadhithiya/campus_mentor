import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // themeNotifier
import '../auth/login_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            _darkMode = prefs.getBool('isDark') ?? false;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Preferences
                _buildGroupTitle('Preferences'),
                const SizedBox(height: 8),
                const SizedBox(height: 20),
                _buildGroupTitle('Support'),
                const SizedBox(height: 8),
                _buildSettingsCard([
                  _buildTapRow(
                    'Help & FAQs',
                    Icons.help_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpScreen(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 20),

                _buildSettingsCard([
                  _buildToggleRow(
                    'Notifications',
                    Icons.notifications_outlined,
                    _notificationsEnabled,
                    (val) => setState(() => _notificationsEnabled = val),
                  ),
                  _buildDivider(),
                  _buildToggleRow(
                    'Dark Mode',
                    Icons.dark_mode_outlined,
                    _darkMode,
                    (val) async {
                      setState(() => _darkMode = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isDark', val);
                      themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                // Account
                _buildGroupTitle('Account'),
                const SizedBox(height: 8),
                _buildSettingsCard([
                  _buildTapRow(
                    'Change Password',
                    Icons.lock_outline,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset email sent!'),
                          backgroundColor: Color(0xFF22C55E),
                        ),
                      );
                      FirebaseAuth.instance.sendPasswordResetEmail(
                        email: FirebaseAuth.instance.currentUser?.email ?? '',
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildTapRow(
                    'Email Address',
                    Icons.email_outlined,
                    trailing: Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 20),

                // About
                _buildGroupTitle('About'),
                const SizedBox(height: 8),
                _buildSettingsCard([
                  _buildTapRow(
                    'App Version',
                    Icons.info_outline,
                    trailing: const Text(
                      'v1.0.0',
                      style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildTapRow(
                    'Privacy Policy',
                    Icons.privacy_tip_outlined,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildTapRow(
                    'Terms of Service',
                    Icons.description_outlined,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildTapRow(
                    'Rate the App',
                    Icons.star_outline,
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 20),

                // Sign out
                _buildSettingsCard([
                  _buildTapRow(
                    'Sign Out',
                    Icons.logout,
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: _signOut,
                  ),
                ]),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTapRow(
    String label,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor ?? colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
            if (trailing == null && onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
      indent: 16,
      endIndent: 16,
    );
  }
}
