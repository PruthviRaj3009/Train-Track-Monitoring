import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:train_track_monitoring/models/robot_status_message.dart';
import 'package:train_track_monitoring/services/websocket_service.dart';

/// Enum representing track condition derived from sensor thresholds.
enum TrackCondition { normal, warning, critical }

/// Immutable snapshot of live sensor values.
class LiveTrackMetrics {
  const LiveTrackMetrics({
    required this.vibrationLevelMmPerS,
    required this.shockImpactCount,
    required this.trackTiltAngleDeg,
    required this.railTemperatureC,
    required this.ambientHumidityPct,
    required this.lightLux,
    required this.isDaylight,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.distanceTravelledKm,
    required this.robotSpeedKmh,
    required this.condition,
  });

  final double vibrationLevelMmPerS;
  final int shockImpactCount;
  final double trackTiltAngleDeg;
  final double railTemperatureC;
  final double ambientHumidityPct;
  final double lightLux;
  final bool isDaylight;
  final double gpsLatitude;
  final double gpsLongitude;
  final double distanceTravelledKm;
  final double robotSpeedKmh;
  final TrackCondition condition;

  bool get isAlert => condition != TrackCondition.normal;
}

class LiveTrackMonitoringPage extends StatefulWidget {
  const LiveTrackMonitoringPage({super.key});

  @override
  State<LiveTrackMonitoringPage> createState() =>
      _LiveTrackMonitoringPageState();
}

class _LiveTrackMonitoringPageState extends State<LiveTrackMonitoringPage> {
  // Use singleton instance instead of creating new instance
  final WebSocketService _websocketService = WebSocketService.instance;
  StreamSubscription<RobotStatusMessage>? _wsSubscription;
  StreamSubscription<Position>? _gpsSubscription;

  LiveTrackMetrics? _metrics;

  // Separate state for telemetry and GPS
  double _vibrationLevel = 0.0;
  int _shockImpactCount = 0;
  double _trackTiltAngle = 0.0;
  double _railTemperature = 0.0;
  double _ambientHumidity = 0.0;
  double _lightLux = 0.0;
  double _distanceTravelled = 0.0;
  double _robotSpeed = 0.0;

  double _gpsLatitude = 0.0;
  double _gpsLongitude = 0.0;

  // Thresholds for condition determination
  static const double _warningVibration = 12.0;
  static const double _criticalVibration = 20.0;

  @override
  void initState() {
    super.initState();

    log('[LIVE_TRACK] Initializing live track monitoring page');

    // Retain reference to singleton WebSocket service
    _websocketService.retain();

    // Connect to WebSocket (will auto-connect if first page)
    log('[LIVE_TRACK] Connecting to WebSocket for telemetry messages');

    // Listen to WebSocket telemetry messages
    _wsSubscription = _websocketService.messageStream.listen((message) {
      log('[LIVE_TRACK] Received message type: ${message.messageType}');
      if (message.isTelemetry) {
        log('[LIVE_TRACK] Processing telemetry message');
        _handleTelemetryUpdate(message);
      } else {
        log(
          '[LIVE_TRACK] Ignoring non-telemetry message: ${message.messageType}',
        );
      }
    });

    // Start GPS location stream
    log('[LIVE_TRACK] Starting GPS location stream');
    _startGPSStream();
  }

  /// Starts the GPS location stream using Geolocator
  Future<void> _startGPSStream() async {
    log('[GPS] Checking location services...');

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('[GPS] ERROR - Location services are disabled');
      log('[GPS] Please enable location services in device settings');
      return;
    }
    log('[GPS] Location services enabled ✓');

    // Check location permission
    log('[GPS] Checking location permissions...');
    LocationPermission permission = await Geolocator.checkPermission();
    log('[GPS] Current permission: $permission');

    if (permission == LocationPermission.denied) {
      log('[GPS] Permission denied - requesting permission...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log('[GPS] ERROR - Permission denied by user');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log(
        '[GPS] ERROR - Permission denied forever - user must enable in settings',
      );
      return;
    }

    log('[GPS] Location permission granted ✓');

    // Get initial position
    try {
      log('[GPS] Getting initial position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      log(
        '[GPS] Initial position: lat=${position.latitude}, lon=${position.longitude}',
      );
      _updateGPSPosition(position);
    } catch (e) {
      log('[GPS] ERROR getting initial position: $e');
      // Ignore errors, will retry with stream
    }

    // Start position stream
    log('[GPS] Starting continuous position stream (updates every 4 meters)');
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 4, // Update every 4 meters
    );

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_updateGPSPosition);

    log('[GPS] GPS stream active ✓');
  }

  /// Updates GPS position and rebuilds metrics
  void _updateGPSPosition(Position position) {
    log(
      '[GPS] Position update: lat=${position.latitude.toStringAsFixed(6)}, lon=${position.longitude.toStringAsFixed(6)}',
    );
    log('[GPS] Accuracy: ${position.accuracy}m, Speed: ${position.speed}m/s');

    setState(() {
      _gpsLatitude = position.latitude;
      _gpsLongitude = position.longitude;
      _updateMetrics();
    });
  }

  /// Handles incoming telemetry data from WebSocket
  void _handleTelemetryUpdate(RobotStatusMessage message) {
    final data = message.data;

    log('[LIVE_TRACK] Extracting telemetry data from WebSocket');

    // Extract telemetry fields
    _vibrationLevel = (data['vibrationLevelMmPerS'] as num?)?.toDouble() ?? 0.0;
    _shockImpactCount = data['shockImpactCount'] as int? ?? 0;
    _trackTiltAngle = (data['trackTiltAngleDeg'] as num?)?.toDouble() ?? 0.0;
    _railTemperature = (data['railTemperatureC'] as num?)?.toDouble() ?? 0.0;
    _ambientHumidity = (data['ambientHumidityPct'] as num?)?.toDouble() ?? 0.0;
    _lightLux = (data['lightLux'] as num?)?.toDouble() ?? 0.0;
    _distanceTravelled =
        (data['distanceTravelledKm'] as num?)?.toDouble() ?? 0.0;
    _robotSpeed = (data['robotSpeedKmh'] as num?)?.toDouble() ?? 0.0;

    log(
      '[LIVE_TRACK] Telemetry: vibration=${_vibrationLevel}mm/s, shock=$_shockImpactCount, tilt=${_trackTiltAngle}°',
    );
    log(
      '[LIVE_TRACK] Telemetry: temp=${_railTemperature}°C, humidity=${_ambientHumidity}%, light=${_lightLux}lux',
    );
    log(
      '[LIVE_TRACK] Telemetry: distance=${_distanceTravelled}km, speed=${_robotSpeed}km/h',
    );

    setState(() {
      _updateMetrics();
    });
  }

  /// Combines telemetry + GPS data into single metrics object
  void _updateMetrics() {
    // Determine track condition based on vibration level
    TrackCondition condition = TrackCondition.normal;
    if (_vibrationLevel >= _criticalVibration) {
      condition = TrackCondition.critical;
    } else if (_vibrationLevel >= _warningVibration) {
      condition = TrackCondition.warning;
    }

    log('[LIVE_TRACK] Combining WebSocket telemetry + GPS data');
    log(
      '[LIVE_TRACK] Track condition: $condition (vibration=${_vibrationLevel}mm/s)',
    );
    log(
      '[LIVE_TRACK] GPS coordinates: (${_gpsLatitude.toStringAsFixed(6)}, ${_gpsLongitude.toStringAsFixed(6)})',
    );

    _metrics = LiveTrackMetrics(
      vibrationLevelMmPerS: _vibrationLevel,
      shockImpactCount: _shockImpactCount,
      trackTiltAngleDeg: _trackTiltAngle,
      railTemperatureC: _railTemperature,
      ambientHumidityPct: _ambientHumidity,
      lightLux: _lightLux,
      isDaylight: _lightLux > 8000,
      gpsLatitude: _gpsLatitude,
      gpsLongitude: _gpsLongitude,
      distanceTravelledKm: _distanceTravelled,
      robotSpeedKmh: _robotSpeed,
      condition: condition,
    );

    log('[LIVE_TRACK] Metrics updated and UI refreshed');
  }

  @override
  void dispose() {
    log('[LIVE_TRACK] Disposing live track monitoring page');
    log('[LIVE_TRACK] Cancelling WebSocket subscription');
    _wsSubscription?.cancel();
    log('[LIVE_TRACK] Cancelling GPS subscription');
    _gpsSubscription?.cancel();
    // Release reference (will only disconnect if no other pages using it)
    _websocketService.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics;

    return Container(
      color: const Color(0xFFF2F5FA),
      child: SafeArea(
        child: metrics == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _AlertBanner(metrics: metrics),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 12.0;
                          final maxWidth = constraints.maxWidth;
                          final twoCol = maxWidth >= 640;
                          final itemWidth = twoCol
                              ? (maxWidth - gap) / 2
                              : maxWidth;

                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Track Condition',
                                  value: _conditionLabel(metrics.condition),
                                  unit: '',
                                  icon: Icons.verified,
                                  accentColor: _conditionColor(
                                    metrics.condition,
                                  ),
                                  subtitle:
                                      'Auto status based on vibration thresholds',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Vibration Level',
                                  value: metrics.vibrationLevelMmPerS
                                      .toStringAsFixed(1),
                                  unit: 'mm/s',
                                  icon: Icons.graphic_eq,
                                  accentColor: _conditionColor(
                                    metrics.condition,
                                  ),
                                  subtitle: 'Live from telemetry WebSocket',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Shock / Impact Count',
                                  value: metrics.shockImpactCount.toString(),
                                  unit: 'events',
                                  icon: Icons.bolt,
                                  accentColor: const Color(0xFF60A5FA),
                                  subtitle: 'Cumulative counter',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Track Tilt / Alignment Angle',
                                  value: metrics.trackTiltAngleDeg
                                      .toStringAsFixed(2),
                                  unit: '°',
                                  icon: Icons.sync_alt,
                                  accentColor: const Color(0xFFA78BFA),
                                  subtitle: 'Estimated alignment deviation',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Rail Temperature',
                                  value: metrics.railTemperatureC
                                      .toStringAsFixed(1),
                                  unit: '°C',
                                  icon: Icons.thermostat,
                                  accentColor: const Color(0xFFF97316),
                                  subtitle: metrics.isDaylight
                                      ? 'Daytime profile'
                                      : 'Night profile',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Ambient Humidity',
                                  value: metrics.ambientHumidityPct
                                      .toStringAsFixed(0),
                                  unit: '%',
                                  icon: Icons.water_drop,
                                  accentColor: const Color(0xFF38BDF8),
                                  subtitle: 'Relative humidity',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Light Intensity',
                                  value: metrics.lightLux.toStringAsFixed(0),
                                  unit: 'lux',
                                  icon: Icons.wb_sunny,
                                  accentColor: metrics.isDaylight
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFF94A3B8),
                                  subtitle: metrics.isDaylight
                                      ? 'Day'
                                      : 'Night',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'GPS Location',
                                  value:
                                      '${metrics.gpsLatitude.toStringAsFixed(5)}, ${metrics.gpsLongitude.toStringAsFixed(5)}',
                                  unit: '',
                                  icon: Icons.gps_fixed,
                                  accentColor: const Color(0xFF22C55E),
                                  subtitle: 'Latitude, Longitude',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Distance Travelled',
                                  value: metrics.distanceTravelledKm
                                      .toStringAsFixed(2),
                                  unit: 'km',
                                  icon: Icons.route,
                                  accentColor: const Color(0xFF34D399),
                                  subtitle: 'From telemetry data',
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MetricCard(
                                  title: 'Robot Speed',
                                  value: metrics.robotSpeedKmh.toStringAsFixed(
                                    1,
                                  ),
                                  unit: 'km/h',
                                  icon: Icons.speed,
                                  accentColor: const Color(0xFF14B8A6),
                                  subtitle: 'Current travel speed',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static String _conditionLabel(TrackCondition c) {
    switch (c) {
      case TrackCondition.normal:
        return 'Normal';
      case TrackCondition.warning:
        return 'Warning';
      case TrackCondition.critical:
        return 'Critical';
    }
  }

  static Color _conditionColor(TrackCondition c) {
    // Professional status tones (avoid neon/over-saturation)
    switch (c) {
      case TrackCondition.normal:
        return const Color(0xFF166534); // deep green
      case TrackCondition.warning:
        return const Color(0xFFD97706); // warm amber
      case TrackCondition.critical:
        return const Color(0xFF991B1B); // deep red
    }
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.metrics});

  final LiveTrackMetrics metrics;

  @override
  Widget build(BuildContext context) {
    if (!metrics.isAlert) {
      return const SizedBox.shrink();
    }

    final isCritical = metrics.condition == TrackCondition.critical;
    final bg = isCritical ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB);
    final border = isCritical
        ? const Color(0xFF991B1B)
        : const Color(0xFFD97706);
    final text = isCritical ? 'CRITICAL' : 'WARNING';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withOpacity(0.55), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1E3A).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: border),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$text: Elevated vibration detected (${metrics.vibrationLevelMmPerS.toStringAsFixed(1)} mm/s).',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF7FAFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF0B1E3A).withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            unit,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
