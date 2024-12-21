import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotfiy_rec/services/user.dart';
import 'package:spotfiy_rec/widgets/custom_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserAuthService _auth = UserAuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _auth.getUserData(user.uid);
        setState(() => _userData = userData);
      }
    } catch (e) {
      print('Error loading user data: $e');
      // TODO: Show error message
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error signing out: $e');
      // TODO: Show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                _userData?['name']?[0] ?? '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userData?['name'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          'Account',
                          [
                            _buildListTile(
                              'Email',
                              _userData?['email'] ?? 'Not available',
                              Icons.email,
                            ),
                            _buildListTile(
                              'Member Since',
                              _formatDate(_userData?['createdAt']),
                              Icons.calendar_today,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          'Preferences',
                          [
                            _buildListTile(
                              'Language',
                              'English',
                              Icons.language,
                              onTap: () {
                                // TODO: Implement language selection
                              },
                            ),
                            _buildListTile(
                              'Theme',
                              'Dark',
                              Icons.palette,
                              onTap: () {
                                // TODO: Implement theme selection
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Sign Out',
                          onPressed: _signOut,
                          isOutlined: true,
                          icon: Icons.exit_to_app,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[400]),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[400],
        ),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not available';
    if (date is DateTime) {
      return '${date.month}/${date.day}/${date.year}';
    }
    return 'Not available';
  }
}