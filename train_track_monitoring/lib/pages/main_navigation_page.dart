import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:train_track_monitoring/pages/alerts_defect_log_page.dart';
import 'package:train_track_monitoring/pages/dashboard_page.dart';
import 'package:train_track_monitoring/pages/live_track_monitoring_page.dart';
import 'package:train_track_monitoring/pages/login_page.dart';
import 'package:train_track_monitoring/pages/map_page.dart';
import 'package:train_track_monitoring/pages/robotic_arm_control_page.dart';
import 'package:train_track_monitoring/services/websocket_service.dart';
import 'package:train_track_monitoring/widgets/app_drawer.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  /// Logout user from Firebase and navigate to login page
  Future<void> _logout() async {
    // Show confirmation dialog
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFB91C1C), size: 28),
              SizedBox(width: 12),
              Text('Confirm Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?\n\nYou will need to sign in again to access the app.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // If user cancelled or dialog was dismissed
    if (confirmLogout != true || !mounted) return;

    // Perform logout operations
    try {
      // 1. Disconnect WebSocket service to clean up resources
      await WebSocketService.instance.disconnect();

      // 2. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 3. Clear navigation stack and navigate to login page
      if (!mounted) return;

      // Use pushAndRemoveUntil to clear entire navigation stack
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      // Handle any errors during logout
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  late final List<Widget> _pages = <Widget>[
    const RoboticArmControlPage(),
    const LiveTrackMonitoringPage(),
    const DashboardPage(),
    const AlertsDefectLogPage(),
    const MapPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3C5D),
        foregroundColor: Colors.white,
        title: Text(
          const [
            'Robotic Arm',
            'Live Track',
            'Dashboard',
            'Alerts',
            'Location',
          ][_selectedIndex],
        ),
        actions: [
          if (_selectedIndex == 1) ...[
            const _LiveBadge(),
            const SizedBox(width: 12),
          ],
        ],
      ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
        onLogout: _logout,
      ),
      body: _pages[_selectedIndex],
      // bottomNavigationBar: SizedBox(
      //   height: 65,
      //   child: BottomNavigationBar(
      //     iconSize: 20,
      //     currentIndex: _selectedIndex,
      //     selectedItemColor: Colors.blue,
      //     unselectedItemColor: Colors.grey,
      //     type: BottomNavigationBarType.fixed,
      //     selectedLabelStyle: const TextStyle(fontSize: 14),
      //     unselectedLabelStyle: const TextStyle(fontSize: 12),
      //     onTap: (i) => setState(() => _selectedIndex = i),
      //     items: const [
      //       BottomNavigationBarItem(
      //         icon: Icon(
      //           Icons.precision_manufacturing,
      //           color: Color(0xFF0B3C5D),
      //         ),
      //         label: 'Robotic Arm',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.sensors, color: Color(0xFF0B3C5D)),
      //         label: 'Live Track',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.dashboard_outlined, color: Color(0xFF0B3C5D)),
      //         label: 'Dashboard',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(
      //           Icons.warning_amber_rounded,
      //           color: Color.fromARGB(255, 242, 45, 23),
      //         ),
      //         label: 'Alerts',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.location_on, color: Color(0xFF0B3C5D)),
      //         label: 'Location',
      //       ),
      //     ],
      //   ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0B3C5D),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        iconSize: 22,
        selectedFontSize: 15,
        unselectedFontSize: 10,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: 'Robotic Arm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'Live Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1E3A).withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
