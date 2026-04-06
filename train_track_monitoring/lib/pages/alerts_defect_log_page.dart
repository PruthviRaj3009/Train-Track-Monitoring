import 'package:flutter/material.dart';
import 'package:train_track_monitoring/models/robot_control_message.dart';
import 'package:train_track_monitoring/models/robot_status_message.dart';
import 'dart:async';
import 'dart:developer';

import 'package:train_track_monitoring/services/websocket_service.dart';

enum AlertSeverity { normal, warning, critical }

enum AlertStatus { pending, acknowledged }

class AlertDefect {
  AlertDefect({
    required this.alertId,
    required this.defectType,
    required this.severity,
    required this.location,
    required this.dateTime,
    this.status = AlertStatus.pending,
  });

  final String alertId;
  final String defectType;
  final AlertSeverity severity;
  final String location;
  final DateTime dateTime;
  AlertStatus status;
}

class AlertsDefectLogPage extends StatefulWidget {
  const AlertsDefectLogPage({super.key});

  @override
  State<AlertsDefectLogPage> createState() => _AlertsDefectLogPageState();
}

class _AlertsDefectLogPageState extends State<AlertsDefectLogPage> {
  // Use singleton instance instead of creating new instance
  final WebSocketService _websocketService = WebSocketService.instance;
  StreamSubscription<RobotStatusMessage>? _messageSubscription;

  List<AlertDefect> _alerts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    log('[ALERTS] Initializing alerts/defect log page');

    // Retain reference to singleton WebSocket service
    _websocketService.retain();

    // Connect to WebSocket (will auto-connect if first page)
    log('[ALERTS] Connecting to WebSocket for alert messages');

    // Listen to WebSocket alert messages
    _messageSubscription = _websocketService.messageStream.listen((message) {
      log('[ALERTS] Received message type: ${message.messageType}');
      if (message.isAlert) {
        log('[ALERTS] Processing alert message');
        _handleNewAlert(message);
      } else {
        log('[ALERTS] Ignoring non-alert message: ${message.messageType}');
      }
    });
  }

  /// Handles incoming alert from WebSocket
  void _handleNewAlert(RobotStatusMessage message) {
    final data = message.data;

    log('[ALERTS] Extracting alert data from WebSocket message');

    // Extract alert fields
    final alertId =
        data['alertId'] as String? ?? data['id'] as String? ?? 'UNKNOWN';
    final defectType =
        data['defectType'] as String? ??
        data['type'] as String? ??
        'Unknown Defect';
    final severityStr = data['severity'] as String? ?? 'normal';
    final latitude = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final timestamp =
        data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final locationStr = data['location'] as String?;

    log(
      '[ALERTS] Alert ID: $alertId, Type: $defectType, Severity: $severityStr',
    );
    log('[ALERTS] Location: lat=$latitude, lon=$longitude');

    // Convert severity string to enum
    AlertSeverity severity = AlertSeverity.normal;
    switch (severityStr.toLowerCase()) {
      case 'critical':
        severity = AlertSeverity.critical;
        break;
      case 'warning':
        severity = AlertSeverity.warning;
        break;
      default:
        severity = AlertSeverity.normal;
    }

    // Build location string
    String location;
    if (locationStr != null && locationStr.isNotEmpty) {
      location = locationStr;
    } else if (latitude != 0.0 || longitude != 0.0) {
      location =
          '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    } else {
      location = 'Unknown Location';
    }

    final newAlert = AlertDefect(
      alertId: alertId,
      defectType: defectType,
      severity: severity,
      location: location,
      dateTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
      status: AlertStatus.pending,
    );

    log(
      '[ALERTS] New alert created: $defectType (${severity.toString().split('.').last})',
    );

    setState(() {
      _alerts.insert(0, newAlert); // Add to top of list
      _alerts.sort(_alertSort); // Re-sort by severity and time
      log('[ALERTS] Alert added to list. Total alerts: ${_alerts.length}');
    });
  }

  @override
  void dispose() {
    log('[ALERTS] Disposing alerts/defect log page');
    log('[ALERTS] Cancelling WebSocket subscription');
    _messageSubscription?.cancel();
    // Release reference (will only disconnect if no other pages using it)
    _websocketService.release();
    super.dispose();
  }

  int _alertSort(AlertDefect a, AlertDefect b) {
    final severityCmp = _severityRank(
      a.severity,
    ).compareTo(_severityRank(b.severity));
    if (severityCmp != 0) return severityCmp;
    return b.dateTime.compareTo(a.dateTime);
  }

  int _severityRank(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return 0;
      case AlertSeverity.warning:
        return 1;
      case AlertSeverity.normal:
        return 2;
    }
  }

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.normal:
        return const Color(0xFF1B5E20);
      case AlertSeverity.warning:
        return const Color(0xFFE65100);
      case AlertSeverity.critical:
        return const Color(0xFFB71C1C);
    }
  }

  String _severityLabel(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.normal:
        return 'Normal';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  String _statusLabel(AlertStatus s) {
    switch (s) {
      case AlertStatus.pending:
        return 'Pending';
      case AlertStatus.acknowledged:
        return 'Acknowledged';
    }
  }

  void _acknowledge(AlertDefect alert) {
    if (alert.status == AlertStatus.acknowledged) {
      log('[ALERTS] Alert ${alert.alertId} already acknowledged - skipping');
      return;
    }

    log('[ALERTS] Acknowledging alert: ${alert.alertId}');

    // Send acknowledgment to robot via WebSocket
    final message = RobotControlMessage.alertAcknowledgment(
      alertId: alert.alertId,
    );

    log('[ALERTS] Sending acknowledgment message to WebSocket');
    _websocketService.sendMessage(message);

    setState(() {
      alert.status = AlertStatus.acknowledged;
      log('[ALERTS] Alert ${alert.alertId} marked as acknowledged in UI');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE9EEF5),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No alerts received yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Alerts will appear here when received from the robot',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final a = _alerts[index];
                final severityColor = _severityColor(a.severity);
                final acknowledged = a.status == AlertStatus.acknowledged;

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: acknowledged
                          ? [const Color(0xFFCFD8DC), const Color(0xFFECEFF1)]
                          : [severityColor.withOpacity(0.15), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: severityColor,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.defectType,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: severityColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _severityLabel(a.severity),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _FieldRow(label: 'Alert ID', value: a.alertId),
                        _FieldRow(label: 'Location', value: a.location),
                        _FieldRow(
                          label: 'Date & Time',
                          value: a.dateTime.toLocal().toString(),
                        ),
                        _FieldRow(
                          label: 'Status',
                          value: _statusLabel(a.status),
                          valueStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: acknowledged
                                ? const Color(0xFF2E7D32)
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: acknowledged
                                  ? Colors.grey
                                  : severityColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: acknowledged
                                ? null
                                : () => _acknowledge(a),
                            child: const Text(
                              'Acknowledge',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value, this.valueStyle});

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF455A64),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
