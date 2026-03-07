import 'dart:async';

import 'package:flutter/material.dart';
import 'package:train_track_monitoring/models/robot_status_message.dart';
import 'package:train_track_monitoring/services/websocket_service.dart';

/// Dashboard (Summary Page) for a Train Track Monitoring application.
///
/// Purpose:
/// - Acts as the primary overview screen when the app opens.
/// - Fetches the latest sensor data (mock for now) and updates the UI dynamically.
/// - Displays key operational metrics and health indicators using status cards.
///
/// Notes for future backend integration:
/// - Replace [_DashboardRepository.fetchLatestSensorData] with a real API call.
/// - Keep the public shape of [DashboardSensorData] stable to minimize UI changes.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

/// State management for [DashboardPage].
///
/// Responsibilities:
/// - Initiate data fetch on load.
/// - Store the latest [DashboardSensorData].
/// - Compute derived UI states (colors, labels, banners) based on data.
class _DashboardPageState extends State<DashboardPage> {
  // Use singleton instance instead of creating new instance
  final WebSocketService _websocketService = WebSocketService.instance;
  StreamSubscription<RobotStatusMessage>? _messageSubscription;

  /// Holds the most recent sensor snapshot used to render the dashboard.
  DashboardSensorData? _data;

  /// True while loading the latest snapshot.
  bool _isLoading = true;

  /// Holds an error message if fetching fails.
  String? _error;

  @override
  void initState() {
    super.initState();

    print('[DASHBOARD] Initializing dashboard page');

    // Retain reference to singleton WebSocket service
    _websocketService.retain();

    // Connect to WebSocket (will auto-connect if first page)
    print('[DASHBOARD] Connecting to WebSocket for system_status messages');
    print('[DASHBOARD] WebSocket connected: ${_websocketService.isConnected}');

    // Listen to WebSocket system status messages
    _messageSubscription = _websocketService.messageStream.listen((message) {
      print('[DASHBOARD] ✅ Received message type: ${message.messageType}');
      print('[DASHBOARD] ✅ Raw data keys: ${message.data.keys.toList()}');
      if (message.isSystemStatus) {
        print('[DASHBOARD] ✅ Processing system_status message');
        _handleSystemStatusUpdate(message);
      } else {
        print(
          '[DASHBOARD] ⚠️ Ignoring non-system_status message: ${message.messageType}',
        );
      }
    });

    // Set timeout: if no data received within 10 seconds, show error (increased from 5s)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        print(
          '[DASHBOARD] ⚠️ Timeout - no system_status data received within 10 seconds',
        );
        print(
          '[DASHBOARD] ⚠️ Check: 1) ESP32 sending system_status? 2) Correct messageType? 3) WebSocket connected?',
        );
        setState(() {
          _error =
              'No data received from robot. Please check WebSocket connection.';
          _isLoading = false;
        });
      }
    });
  }

  /// Handles incoming system status data from WebSocket
  void _handleSystemStatusUpdate(RobotStatusMessage message) {
    final data = message.data;

    print('[DASHBOARD] ✅ Extracting system_status data from WebSocket message');
    print(
      '[DASHBOARD] ✅ Available fields in message.data: ${data.keys.toList()}',
    );

    // Extract all fields from WebSocket message
    final trackHealthStatus = data['trackHealthStatus'] as String? ?? 'normal';
    final batteryPercentage = data['batteryPercentage'] as int? ?? 0;
    final deviceStatus = data['deviceStatus'] as String? ?? 'offline';
    final currentTrackKm = (data['currentTrackKm'] as num?)?.toDouble() ?? 0.0;
    final totalDefectsDetected = data['totalDefectsDetected'] as int? ?? 0;
    final criticalDefectsCount = data['criticalDefectsCount'] as int? ?? 0;
    final lastUpdate =
        data['lastUpdate'] as String? ?? DateTime.now().toIso8601String();
    final currentTrackSection =
        data['currentTrackSection'] as String? ?? 'Unknown';
    final robotSpeedKmh = (data['robotSpeedKmh'] as num?)?.toDouble() ?? 0.0;

    print('[DASHBOARD_UPDATE] ✅ Battery: $batteryPercentage%');
    print('[DASHBOARD_UPDATE] ✅ Track Health: $trackHealthStatus');
    print('[DASHBOARD_UPDATE] ✅ Device: $deviceStatus');
    print(
      '[DASHBOARD_UPDATE] ✅ Defects: Total=$totalDefectsDetected, Critical=$criticalDefectsCount',
    );
    print(
      '[DASHBOARD_UPDATE] ✅ Location: Section=$currentTrackSection, KM=$currentTrackKm',
    );
    print('[DASHBOARD_UPDATE] ✅ Speed: $robotSpeedKmh km/h');

    // Convert string status to enum
    TrackHealthStatus trackHealth;
    switch (trackHealthStatus.toLowerCase()) {
      case 'critical':
        trackHealth = TrackHealthStatus.critical;
        break;
      case 'warning':
        trackHealth = TrackHealthStatus.warning;
        break;
      default:
        trackHealth = TrackHealthStatus.normal;
    }

    DeviceStatus device;
    switch (deviceStatus.toLowerCase()) {
      case 'online':
        device = DeviceStatus.online;
        break;
      default:
        device = DeviceStatus.offline;
    }

    setState(() {
      _isLoading = false;
      _error = null;
      _data = DashboardSensorData(
        trackHealthStatus: trackHealth,
        deviceStatus: device,
        lastUpdate: DateTime.parse(lastUpdate),
        currentTrackKm: currentTrackKm,
        currentTrackSection: currentTrackSection,
        robotSpeedKmh: robotSpeedKmh,
        totalDefectsDetected: totalDefectsDetected,
        criticalDefectsCount: criticalDefectsCount,
        batteryPercentage: batteryPercentage,
      );
    });

    print(
      '[DASHBOARD] ✅✅✅ setState() called - Dashboard UI updated with new system_status data',
    );
    print(
      '[DASHBOARD] ✅✅✅ UI should now show: Battery=$batteryPercentage%, Health=$trackHealth, Device=$device',
    );
  }

  @override
  void dispose() {
    print('[DASHBOARD] Disposing dashboard page');
    _messageSubscription?.cancel();
    // Release reference (will only disconnect if no other pages using it)
    _websocketService.release();
    super.dispose();
  }

  /// Triggers a manual refresh (reconnects WebSocket if needed)
  Future<void> _loadLatest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Reconnect WebSocket to get fresh data
      await _websocketService.connect();

      // Loading state will be cleared when first message arrives
      // If no message arrives within timeout, show error (increased to 10s)
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isLoading) {
          print(
            '[DASHBOARD] ⚠️ Manual refresh timeout - no system_status data received',
          );
          setState(() {
            _error = 'No data received from robot.';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to connect to robot.';
        _isLoading = false;
      });
    }
  }

  /// Maps [TrackHealthStatus] to a consistent status color.
  Color _trackHealthColor(TrackHealthStatus status) {
    switch (status) {
      case TrackHealthStatus.normal:
        return Colors.green;
      case TrackHealthStatus.warning:
        return Colors.orange;
      case TrackHealthStatus.critical:
        return Colors.red;
    }
  }

  /// Returns a label for [TrackHealthStatus] suitable for display.
  String _trackHealthLabel(TrackHealthStatus status) {
    switch (status) {
      case TrackHealthStatus.normal:
        return 'Normal';
      case TrackHealthStatus.warning:
        return 'Warning';
      case TrackHealthStatus.critical:
        return 'Critical';
    }
  }

  /// Maps [DeviceStatus] to a consistent indicator color.
  Color _deviceStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return Colors.green;
      case DeviceStatus.offline:
        // Grey or red indicator as requested; grey is less visually aggressive.
        return Colors.grey;
    }
  }

  /// Returns a label for [DeviceStatus] suitable for display.
  String _deviceStatusLabel(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return 'Online';
      case DeviceStatus.offline:
        return 'Offline';
    }
  }

  /// Derives battery color based on percentage thresholds.
  ///
  /// Rules:
  /// - < 10%  => critical red indicator
  /// - < 20%  => warning orange indicator
  /// - else  => healthy green indicator
  Color _batteryColor(int batteryPercentage) {
    if (batteryPercentage < 10) return Colors.red;
    if (batteryPercentage < 20) return Colors.orange;
    return Colors.green;
  }

  /// Whether to show a warning icon next to battery percentage.
  ///
  /// Rules:
  /// - < 20% => show warning icon (includes critical range)
  bool _showBatteryWarningIcon(int batteryPercentage) {
    return batteryPercentage < 20;
  }

  /// Formats a timestamp into a concise, readable string without extra deps.
  String _formatLastUpdate(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Container(
      color: const Color(0xFFF2F5FA),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _loadLatest)
          : data == null
          ? _ErrorState(message: 'No data available.', onRetry: _loadLatest)
          : RefreshIndicator(
              onRefresh: _loadLatest,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid:
                  // - Mobile: 2 cards per row
                  // - Wider screens: expand to 3+ columns for better density
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 900
                      ? 4
                      : width >= 600
                      ? 3
                      : 2;

                  final trackHealthColor = _trackHealthColor(
                    data.trackHealthStatus,
                  );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      // Critical alert banner shown only when track health is critical.
                      if (data.trackHealthStatus == TrackHealthStatus.critical)
                        _CriticalAlertBanner(
                          message:
                              'Critical track health detected. Immediate attention required.',
                        ),

                      if (data.trackHealthStatus == TrackHealthStatus.critical)
                        const SizedBox(height: 12),

                      // Title / context header.
                      _DashboardHeader(
                        section: data.currentTrackSection,
                        km: data.currentTrackKm,
                        lastUpdate: _formatLastUpdate(data.lastUpdate),
                      ),

                      const SizedBox(height: 16),

                      // Grid of status cards (clean and consistent).
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          // Track Health Status
                          StatusCard(
                            title: 'Track Health',
                            value: _trackHealthLabel(data.trackHealthStatus),
                            icon: Icons.health_and_safety,
                            accentColor: trackHealthColor,
                          ),

                          // Device Status
                          StatusCard(
                            title: 'Device Status',
                            value: _deviceStatusLabel(data.deviceStatus),
                            icon: Icons.router,
                            accentColor: _deviceStatusColor(data.deviceStatus),
                            trailing: _StatusDot(
                              color: _deviceStatusColor(data.deviceStatus),
                            ),
                          ),

                          // Last Update Time
                          StatusCard(
                            title: 'Last Update',
                            value: _formatLastUpdate(data.lastUpdate),
                            icon: Icons.schedule,
                            accentColor: Colors.blueGrey,
                          ),

                          // Current Track KM / Section
                          StatusCard(
                            title: 'Track Location',
                            value:
                                'KM ${data.currentTrackKm.toStringAsFixed(1)}',
                            icon: Icons.alt_route,
                            accentColor: Colors.indigo,
                            subtitle: data.currentTrackSection,
                          ),

                          // Robot Speed (km/h)
                          StatusCard(
                            title: 'Robot Speed',
                            value:
                                '${data.robotSpeedKmh.toStringAsFixed(1)} km/h',
                            icon: Icons.speed,
                            accentColor: Colors.teal,
                          ),

                          // Total Defects Detected
                          StatusCard(
                            title: 'Total Defects',
                            value: data.totalDefectsDetected.toString(),
                            icon: Icons.search,
                            accentColor: Colors.deepPurple,
                          ),

                          // Critical Defects Count
                          StatusCard(
                            title: 'Critical Defects',
                            value: data.criticalDefectsCount.toString(),
                            icon: Icons.warning_amber,
                            accentColor: data.criticalDefectsCount > 0
                                ? Colors.red
                                : Colors.green,
                          ),

                          // Battery Percentage
                          StatusCard(
                            title: 'Battery',
                            value: '${data.batteryPercentage}%',
                            icon: Icons.battery_full,
                            accentColor: _batteryColor(data.batteryPercentage),
                            trailing:
                                _showBatteryWarningIcon(data.batteryPercentage)
                                ? Icon(
                                    data.batteryPercentage < 10
                                        ? Icons.error
                                        : Icons.warning,
                                    color: _batteryColor(
                                      data.batteryPercentage,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Optional: quick legend row to reinforce meaning (kept minimal).
                      _LegendRow(
                        normalColor: Colors.green,
                        warningColor: Colors.orange,
                        criticalColor: Colors.red,
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

/// Reusable status card widget for dashboard metrics.
///
/// Design goals:
/// - Material look via [Card] with elevation.
/// - Consistent icon + title + value layout.
/// - Optional trailing widget (e.g., dot indicator or warning icon).
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
    this.trailing,
  });

  /// Card title (metric name).
  final String title;

  /// Main display value (metric value).
  final String value;

  /// Icon representing the metric.
  final IconData icon;

  /// Accent color used for icon and value styling (updates dynamically).
  final Color accentColor;

  /// Optional small helper text shown under the value.
  final String? subtitle;

  /// Optional widget placed to the right of the value line.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const borderRadius = BorderRadius.all(Radius.circular(12));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1E3A).withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: const Color(0xFFF7FAFF),
        shape: const RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: icon + title.
              Row(
                children: [
                  Icon(icon, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Value row: main value + optional trailing indicator.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Subtitle: kept subtle to avoid clutter.
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475569),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small colored dot used as a status indicator (e.g., Online/Offline).
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  /// Dot color matching the status color.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Banner displayed when track health is critical.
class _CriticalAlertBanner extends StatelessWidget {
  const _CriticalAlertBanner({required this.message});

  /// Alert message to display.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB91C1C),
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.report, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header section that provides context for the current reading.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.section,
    required this.km,
    required this.lastUpdate,
  });

  /// Current track section name/identifier.
  final String section;

  /// Current kilometer marker.
  final double km;

  /// Last update string displayed to the user.
  final String lastUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: const Color(0xFFF7FAFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF0B1E3A).withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Train Track Monitoring',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Section: $section • KM ${km.toStringAsFixed(1)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last update: $lastUpdate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal legend row to indicate status colors (kept unobtrusive).
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.normalColor,
    required this.warningColor,
    required this.criticalColor,
  });

  final Color normalColor;
  final Color warningColor;
  final Color criticalColor;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
          child: item('Normal', normalColor),
        ),
        DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
          child: item('Warning', warningColor),
        ),
        DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
          child: item('Critical', criticalColor),
        ),
      ],
    );
  }
}

/// Error state used when dashboard data fails to load.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  /// Message shown to the user.
  final String message;

  /// Retry callback to attempt data reload.
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Track health statuses used to drive UI color and alert logic.
enum TrackHealthStatus { normal, warning, critical }

/// Device connectivity status used to drive the UI indicator color.
enum DeviceStatus { online, offline }

/// Strongly-typed container for dashboard sensor data.
///
/// This structure is intentionally simple and API-friendly so it can be mapped
/// directly from a backend JSON response in the future.
class DashboardSensorData {
  const DashboardSensorData({
    required this.trackHealthStatus,
    required this.deviceStatus,
    required this.lastUpdate,
    required this.currentTrackKm,
    required this.currentTrackSection,
    required this.robotSpeedKmh,
    required this.totalDefectsDetected,
    required this.criticalDefectsCount,
    required this.batteryPercentage,
  });

  final TrackHealthStatus trackHealthStatus;
  final DeviceStatus deviceStatus;
  final DateTime lastUpdate;
  final double currentTrackKm;
  final String currentTrackSection;
  final double robotSpeedKmh;
  final int totalDefectsDetected;
  final int criticalDefectsCount;
  final int batteryPercentage;
}
