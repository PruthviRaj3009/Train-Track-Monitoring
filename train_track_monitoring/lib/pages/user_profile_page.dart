import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load current Firebase user
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user from Firebase
      final user = FirebaseAuth.instance.currentUser;
      
      // Reload user to get latest data
      if (user != null) {
        await user.reload();
        setState(() {
          _currentUser = FirebaseAuth.instance.currentUser;
        });
      } else {
        setState(() {
          _currentUser = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Format date in readable format
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  /// Get user initials for avatar fallback
  String _getUserInitials() {
    if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      final names = _currentUser!.displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return _currentUser!.displayName![0].toUpperCase();
    }
    if (_currentUser?.email != null) {
      return _currentUser!.email![0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3C5D),
        elevation: 2,
        title: const Text(
          "User Profile",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0B3C5D),
              ),
            )
          : _currentUser == null
              ? _buildNoUserUI()
              : _buildProfileUI(),
    );
  }

  /// Build UI when no user is logged in
  Widget _buildNoUserUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'No User Logged In',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please log in to view your profile',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3C5D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build profile UI with user data
  Widget _buildProfileUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),

          /// Profile Image
          _buildProfileAvatar(),

          const SizedBox(height: 20),

          /// Display Name
          Text(
            _currentUser?.displayName ?? 'No Name Set',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          /// Email
          Text(
            _currentUser?.email ?? 'No Email',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 8),

          /// Email Verification Badge
          if (_currentUser?.emailVerified == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Email Verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Email Not Verified',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 30),

          /// Account Information Card
          Card(
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B3C5D),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _infoRow(
                    'User ID',
                    _currentUser?.uid ?? 'N/A',
                    Icons.fingerprint,
                  ),
                  const Divider(height: 25),
                  _infoRow(
                    'Email',
                    _currentUser?.email ?? 'Not Available',
                    Icons.email_outlined,
                  ),
                  const Divider(height: 25),
                  _infoRow(
                    'Display Name',
                    _currentUser?.displayName ?? 'Not Set',
                    Icons.person_outline,
                  ),
                  const Divider(height: 25),
                  _infoRow(
                    'Phone Number',
                    _currentUser?.phoneNumber ?? 'Not Linked',
                    Icons.phone_outlined,
                  ),
                  const Divider(height: 25),
                  _infoRow(
                    'Account Created',
                    _formatDate(_currentUser?.metadata.creationTime),
                    Icons.calendar_today_outlined,
                  ),
                  const Divider(height: 25),
                  _infoRow(
                    'Last Sign In',
                    _formatDate(_currentUser?.metadata.lastSignInTime),
                    Icons.access_time_outlined,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// Provider Information Card
          if (_currentUser?.providerData != null &&
              _currentUser!.providerData.isNotEmpty)
            Card(
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication Providers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B3C5D),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ..._currentUser!.providerData.map((provider) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              _getProviderIcon(provider.providerId),
                              size: 20,
                              color: const Color(0xFF0B3C5D),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getProviderName(provider.providerId),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 30),

          /// Refresh Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0B3C5D), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh, color: Color(0xFF0B3C5D)),
              label: const Text(
                'Refresh Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B3C5D),
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }

  /// Build profile avatar with photo or initials
  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 55,
      backgroundColor: const Color(0xFF0B3C5D),
      child: _currentUser?.photoURL != null
          ? CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_currentUser!.photoURL!),
              onBackgroundImageError: (_, __) {
                // Fallback to initials if image fails to load
              },
              child: Container(), // Empty container for error handling
            )
          : CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(
                _getUserInitials(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  /// Get icon for authentication provider
  IconData _getProviderIcon(String providerId) {
    switch (providerId) {
      case 'password':
        return Icons.email;
      case 'google.com':
        return Icons.g_mobiledata;
      case 'phone':
        return Icons.phone;
      case 'facebook.com':
        return Icons.facebook;
      default:
        return Icons.security;
    }
  }

  /// Get readable name for authentication provider
  String _getProviderName(String providerId) {
    switch (providerId) {
      case 'password':
        return 'Email/Password';
      case 'google.com':
        return 'Google';
      case 'phone':
        return 'Phone Number';
      case 'facebook.com':
        return 'Facebook';
      default:
        return providerId;
    }
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF0B3C5D),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
