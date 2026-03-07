/// Model for outgoing control messages sent from Flutter to the robot.
///
/// Supports two message types:
/// - "control": Servo angles and speed settings
/// - "alert_acknowledgment": Alert acknowledgment events
class RobotControlMessage {
  final String messageType;
  final Map<String, dynamic> payload;
  final int timestamp;

  RobotControlMessage({
    required this.messageType,
    required this.payload,
  }) : timestamp = DateTime.now().millisecondsSinceEpoch;

  /// Creates a control message for servo positions and speed.
  ///
  /// Example:
  /// ```dart
  /// RobotControlMessage.control(
  ///   grip: 90.0,
  ///   wristPitch: 45.0,
  ///   wristRoll: 120.0,
  ///   elbow: 60.0,
  ///   shoulder: 75.0,
  ///   waist: 90.0,
  ///   speed: 150.0,
  /// );
  /// ```
  factory RobotControlMessage.control({
    required double grip,
    required double wristPitch,
    required double wristRoll,
    required double elbow,
    required double shoulder,
    required double waist,
    required double speed,
  }) {
    return RobotControlMessage(
      messageType: 'control',
      payload: {
        'servos': {
          'grip': grip.round(),
          'wristPitch': wristPitch.round(),
          'wristRoll': wristRoll.round(),
          'elbow': elbow.round(),
          'shoulder': shoulder.round(),
          'waist': waist.round(),
        },
        'speed': speed.round(),
      },
    );
  }

  /// Creates a movement command message.
  ///
  /// Example:
  /// ```dart
  /// RobotControlMessage.movement('forward');
  /// RobotControlMessage.movement('backward');
  /// RobotControlMessage.movement('stop');
  /// ```
  factory RobotControlMessage.movement(String command) {
    return RobotControlMessage(
      messageType: 'control',
      payload: {
        'movement': command,
      },
    );
  }

  /// Creates an alert acknowledgment message.
  ///
  /// Example:
  /// ```dart
  /// RobotControlMessage.alertAcknowledgment(alertId: 'alert_123');
  /// ```
  factory RobotControlMessage.alertAcknowledgment({required String alertId}) {
    return RobotControlMessage(
      messageType: 'alert_acknowledgment',
      payload: {
        'alertId': alertId,
      },
    );
  }

  /// Converts the message to JSON format for transmission.
  Map<String, dynamic> toJson() {
    return {
      'messageType': messageType,
      'timestamp': timestamp,
      'control': payload,
    };
  }
}
