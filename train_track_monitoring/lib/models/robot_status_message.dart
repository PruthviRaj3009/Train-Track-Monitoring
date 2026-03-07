/// Model for incoming status messages received from the robot.
///
/// Supports multiple message types:
/// - "telemetry": Real-time sensor data
/// - "system_status": System health and diagnostics
/// - "alert": New defect/alert events
class RobotStatusMessage {
  final String messageType;
  final int timestamp;
  final Map<String, dynamic> data;

  RobotStatusMessage({
    required this.messageType,
    required this.timestamp,
    required this.data,
  });

  /// Parses incoming JSON into a RobotStatusMessage.
  ///
  /// Extracts nested data based on messageType:
  /// - "system_status" -> extracts json['system']
  /// - "telemetry" -> extracts json['telemetry']
  /// - "alert" -> extracts json['alert']
  factory RobotStatusMessage.fromJson(Map<String, dynamic> json) {
    try {
      final messageType = json['messageType'] as String;
      final timestamp = json['timestamp'] as int;
      
      // Extract nested data based on messageType
      Map<String, dynamic> extractedData;
      
      if (messageType == 'system_status') {
        extractedData = json['system'] as Map<String, dynamic>? ?? {};
        print('[WS_PARSE] messageType: $messageType');
        print('[WS_PARSE] extracted data keys: ${extractedData.keys.toList()}');
      } else if (messageType == 'telemetry') {
        extractedData = json['telemetry'] as Map<String, dynamic>? ?? {};
        print('[WS_PARSE] messageType: $messageType');
        print('[WS_PARSE] extracted data keys: ${extractedData.keys.toList()}');
      } else if (messageType == 'alert') {
        extractedData = json['alert'] as Map<String, dynamic>? ?? {};
        print('[WS_PARSE] messageType: $messageType');
        print('[WS_PARSE] extracted data keys: ${extractedData.keys.toList()}');
      } else {
        // Fallback: use entire json for unknown message types
        extractedData = json;
        print('[WS_PARSE] ⚠️ Unknown messageType: $messageType - using full JSON');
      }
      
      return RobotStatusMessage(
        messageType: messageType,
        timestamp: timestamp,
        data: extractedData,
      );
    } catch (e) {
      print('[WS_PARSE] ❌ JSON parsing failed: $e');
      throw FormatException('Invalid RobotStatusMessage JSON: $e');
    }
  }

  /// Safely parses JSON with error handling.
  static RobotStatusMessage? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return RobotStatusMessage.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  bool get isTelemetry => messageType == 'telemetry';
  bool get isSystemStatus => messageType == 'system_status';
  bool get isAlert => messageType == 'alert';
}

/// Telemetry data model for live monitoring.
class TelemetryData {
  final double vibrationLevel;
  final String trackCondition;
  final double speed;
  final double temperature;
  final double humidity;
  final double lightLevel;

  TelemetryData({
    required this.vibrationLevel,
    required this.trackCondition,
    required this.speed,
    required this.temperature,
    required this.humidity,
    required this.lightLevel,
  });

  factory TelemetryData.fromMessage(RobotStatusMessage message) {
    final data = message.data;
    return TelemetryData(
      vibrationLevel: (data['vibrationLevel'] as num?)?.toDouble() ?? 0.0,
      trackCondition: data['trackCondition'] as String? ?? 'Unknown',
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
      lightLevel: (data['lightLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// System status data model for dashboard.
class SystemStatusData {
  final int batteryPercentage;
  final bool deviceOnline;
  final double latitude;
  final double longitude;
  final double distanceTraveled;
  final int defectsDetected;
  final String trackSection;

  SystemStatusData({
    required this.batteryPercentage,
    required this.deviceOnline,
    required this.latitude,
    required this.longitude,
    required this.distanceTraveled,
    required this.defectsDetected,
    required this.trackSection,
  });

  factory SystemStatusData.fromMessage(RobotStatusMessage message) {
    final data = message.data;
    return SystemStatusData(
      batteryPercentage: data['batteryPercentage'] as int? ?? 0,
      deviceOnline: data['deviceOnline'] as bool? ?? false,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceTraveled: (data['distanceTraveled'] as num?)?.toDouble() ?? 0.0,
      defectsDetected: data['defectsDetected'] as int? ?? 0,
      trackSection: data['trackSection'] as String? ?? 'Unknown',
    );
  }
}

/// Alert/defect data model.
class AlertData {
  final String id;
  final String type;
  final String severity;
  final String description;
  final double latitude;
  final double longitude;
  final int timestamp;

  AlertData({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory AlertData.fromMessage(RobotStatusMessage message) {
    final data = message.data;
    return AlertData(
      id: data['id'] as String? ?? '',
      type: data['type'] as String? ?? 'Unknown',
      severity: data['severity'] as String? ?? 'medium',
      description: data['description'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
