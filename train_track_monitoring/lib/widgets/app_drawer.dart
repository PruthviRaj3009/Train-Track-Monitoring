import 'package:flutter/material.dart';
import 'package:train_track_monitoring/config/websocket_config.dart';
import 'package:train_track_monitoring/pages/about_page.dart';
import 'package:train_track_monitoring/pages/live_stream_view.dart';
import 'package:train_track_monitoring/pages/user_profile_page.dart';
import 'package:train_track_monitoring/services/websocket_service.dart';
// import 'package:loginpage/pages/about_page.dart';
// import 'package:loginpage/pages/user_profile_page.dart';
// import 'package:loginpage/config/websocket_config.dart';
// import 'package:loginpage/services/websocket_service.dart';
// import 'package:loginpage/pages/live_stream_view.dart';

/// IP Address Configuration Type
enum IpConfigType { robot, stream }

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF1F3F5),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF0B3C5D)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text(
                        'Train Track Monitoring',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Navigation',
                        style: TextStyle(
                          color: Color(0xFFB9C6D1),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.precision_manufacturing,
                    color: Color(0xFF0B3C5D),
                  ),
                  title: const Text('Robotic Arm'),
                  selected: selectedIndex == 0,
                  selectedTileColor: const Color(0xFFDEE6EE),
                  selectedColor: const Color(0xFF0B3C5D),
                  onTap: () {
                    onItemSelected(0);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sensors, color: Color(0xFF0B3C5D)),
                  title: const Text('Live Track'),
                  selected: selectedIndex == 1,
                  selectedTileColor: const Color(0xFFDEE6EE),
                  selectedColor: const Color(0xFF0B3C5D),
                  onTap: () {
                    onItemSelected(1);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.dashboard_outlined,
                    color: Color(0xFF0B3C5D),
                  ),
                  title: const Text('Dashboard'),
                  selected: selectedIndex == 2,
                  selectedTileColor: const Color(0xFFDEE6EE),
                  selectedColor: const Color(0xFF0B3C5D),
                  onTap: () {
                    onItemSelected(2);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color.fromARGB(255, 242, 45, 23),
                  ),
                  title: const Text('Alerts'),
                  selected: selectedIndex == 3,
                  selectedTileColor: const Color(0xFFDEE6EE),
                  selectedColor: const Color(0xFF0B3C5D),
                  onTap: () {
                    onItemSelected(3);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Color(0xFF0B3C5D),
                  ),
                  title: const Text('Location'),
                  selected: selectedIndex == 4,
                  selectedTileColor: const Color(0xFFDEE6EE),
                  selectedColor: const Color(0xFF0B3C5D),
                  onTap: () {
                    onItemSelected(4);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.precision_manufacturing,
                    color: Color(0xFF0B3C5D),
                  ),
                  title: const Text('Set Robot IP'),
                  subtitle: const Text('WebSocket control'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showIpAddressDialog(context, IpConfigType.robot);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: Color(0xFF0B3C5D)),
                  title: const Text('Set Stream IP'),
                  subtitle: const Text('Live camera feed'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showIpAddressDialog(context, IpConfigType.stream);
                  },
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF0B3C5D)),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserProfilePage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group, color: Color(0xFF0B3C5D)),
                  title: const Text('Team Members'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showTeamMembersDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0B3C5D),
                  ),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFB91C1C)),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1E3A),
                  ),
                ),
                onTap: () {
                  // Close drawer first, then call logout
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows dialog to display team members
  static void _showTeamMembersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          title: Row(
            children: [
              Icon(Icons.group, color: Color(0xFF0B3C5D), size: 28),
              SizedBox(width: 12),
              Text('Team Members'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Development Team',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),
              _TeamMemberTile(name: 'Jatin Herekar', icon: Icons.person),
              SizedBox(height: 12),
              _TeamMemberTile(name: 'Vishal Mestry', icon: Icons.person),
              SizedBox(height: 12),
              _TeamMemberTile(name: 'Tejas Garje', icon: Icons.person),
            ],
          ),
          actions: [_CloseButton()],
        );
      },
    );
  }

  /// Shows dialog to enter ESP32 IP address
  static void _showIpAddressDialog(
    BuildContext context,
    IpConfigType configType,
  ) async {
    final TextEditingController ipController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Load current IP based on type
    final currentIp = configType == IpConfigType.robot
        ? await NetworkConfig.getRobotIp()
        : await NetworkConfig.getStreamIp();
    ipController.text = currentIp;

    // Configure dialog based on type
    final String title = configType == IpConfigType.robot
        ? 'Enter Robot ESP32 IP'
        : 'Enter ESP32-CAM IP';
    final String subtitle = configType == IpConfigType.robot
        ? 'Used for robot control via WebSocket'
        : 'Used for live video streaming';
    final IconData icon = configType == IpConfigType.robot
        ? Icons.precision_manufacturing
        : Icons.videocam;
    final Color iconColor = const Color(0xFF0B3C5D);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ipController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: '192.168.43.125',
                    labelText: 'IPv4 Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wifi),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an IP address';
                    }
                    // Basic IPv4 validation
                    final ipv4Pattern = RegExp(
                      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
                    );
                    if (!ipv4Pattern.hasMatch(value)) {
                      return 'Invalid IPv4 address format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Format: xxx.xxx.xxx.xxx (0-255 per octet)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newIp = ipController.text.trim();

                  // Save IP based on type
                  if (configType == IpConfigType.robot) {
                    await NetworkConfig.saveRobotIp(newIp);
                  } else {
                    await NetworkConfig.saveStreamIp(newIp);
                  }

                  // Close dialog
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  // Show success message
                  if (context.mounted) {
                    final String deviceName = configType == IpConfigType.robot
                        ? 'Robot ESP32'
                        : 'ESP32-CAM';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$deviceName IP saved: $newIp'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }

                  // Handle reconnection based on type
                  if (configType == IpConfigType.robot) {
                    // Reconnect WebSocket with new Robot IP (DO NOT affect stream)
                    final websocketService = WebSocketService.instance;
                    await websocketService.disconnect();
                    await Future.delayed(const Duration(milliseconds: 500));
                    await websocketService.connect();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reconnecting to robot...'),
                          backgroundColor: Color(0xFF0B3C5D),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    // Reload Live Stream with new Stream IP (DO NOT affect WebSocket)
                    LiveStreamViewState.notifyIpChanged();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reloading live stream...'),
                          backgroundColor: Color(0xFF0B3C5D),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save & Apply'),
            ),
          ],
        );
      },
    );
  }
}

/// Widget to display individual team member
class _TeamMemberTile extends StatelessWidget {
  final String name;
  final IconData icon;

  const _TeamMemberTile({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B3C5D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0B3C5D), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B1E3A),
          ),
        ),
      ],
    );
  }
}

/// Close button for dialogs
class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Close'),
    );
  }
}
