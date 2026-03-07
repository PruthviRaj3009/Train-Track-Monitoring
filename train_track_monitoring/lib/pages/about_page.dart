import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3C5D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'About',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: const [
            _InfoCard(
              title: 'Train Track Monitoring System',
              subtitle: 'Industrial Monitoring Application',
              children: [
                _InfoRow(label: 'Version', value: '1.0.0'),
                SizedBox(height: 12),
                Text(
                  'This project monitors train track conditions and robot telemetry in real time, providing dashboards, alerts, live tracking, and on-site location visualization for safer operations.',
                  style: TextStyle(
                    color: Color(0xFF243447),
                    height: 1.35,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            _InfoCard(
              title: 'Developer',
              subtitle: 'Project Owner / Maintainer',
              children: [
                _InfoRow(label: 'Name', value: 'Developer Name'),
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Core Framework',
              items: [
                'Flutter (SDK >=3.4.1 <4.0.0) - Cross-platform mobile application framework',
                'Dart - Programming language for Flutter',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Backend & Authentication',
              items: [
                'Firebase Core (^2.24.2) - Firebase platform initialization',
                'Firebase Auth (^4.17.3) - User authentication and authorization',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'UI/UX Libraries',
              items: [
                'Material Design - Flutter\'s material design components',
                'Cupertino Icons (^1.0.2) - iOS-style icons',
                'Animate Do (^3.1.2) - Pre-built animations for UI elements',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Maps & Location',
              items: [
                'Google Maps Flutter (^2.5.3) - Interactive map integration',
                'Geolocator (^11.0.0) - Location services and GPS tracking',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Real-time Communication',
              items: [
                'Web Socket Channel (^2.4.0) - WebSocket connectivity for real-time robot control and status updates',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Web View',
              items: [
                'WebView Flutter (^4.8.0) - Embedded web content display',
                'WebView Flutter Android (^3.16.8) - Android-specific WebView implementation',
                'WebView Flutter WKWebView (^3.14.0) - iOS-specific WebView implementation',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Data Persistence',
              items: [
                'Shared Preferences (^2.2.2) - Local key-value storage for app settings',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Development Tools',
              items: [
                'Flutter Test - Testing framework',
                'Flutter Lints (^3.0.0) - Code quality and style linting',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Platform Support',
              items: [
                'Android - Native Android support with Kotlin',
                'iOS - Native iOS support with Swift',
                'Web - Web platform support',
                'Linux - Linux desktop support (C++)',
                'macOS - macOS desktop support (Swift)',
                'Windows - Windows desktop support (C++)',
              ],
            ),
            SizedBox(height: 14),
            _TechSection(
              sectionTitle: 'Key Features Implemented',
              items: [
                'Robot control and monitoring system',
                'Live video streaming via WebView',
                'Real-time GPS tracking',
                'Robotic arm control',
                'User authentication (login/signup)',
                'Dashboard with real-time status updates',
                'Alerts and defect logging',
                'Interactive maps with robot location tracking',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0B3C5D).withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1E3A).withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B1E3A),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B6B7C),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5B6B7C),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0B1E3A),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.circle,
              size: 8,
              color: Color(0xFF0B3C5D),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF243447),
                height: 1.35,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechSection extends StatelessWidget {
  final String sectionTitle;
  final List<String> items;

  const _TechSection({
    required this.sectionTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: sectionTitle,
      subtitle: 'Technologies Used',
      children: [
        ...items.map((item) => _Bullet(text: item)),
      ],
    );
  }
}
