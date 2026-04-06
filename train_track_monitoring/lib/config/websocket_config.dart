import 'package:shared_preferences/shared_preferences.dart';

/// Network Configuration for Dual ESP32 Setup
///
/// This app connects to TWO separate ESP32 devices:
/// 1. Robot ESP32 - Handles WebSocket control and telemetry
/// 2. ESP32-CAM - Handles HTTP live video streaming
///
/// Each device has its own IP address that can be configured independently.
class NetworkConfig {
  /// Default Robot ESP32 IP Address (fallback)
  ///
  /// Used for WebSocket control and telemetry
  static const String defaultRobotIp = '10.93.169.180';

  /// Default ESP32-CAM IP Address (fallback)
  ///
  /// Used for HTTP live streaming
  static const String defaultStreamIp = '10.93.169.127';

  /// WebSocket Server Port (Robot ESP32)
  ///
  /// Default: 81 (standard for ESP32/Arduino WebSocket servers)
  static const int webSocketPort = 81;

  /// HTTP Server Port (ESP32-CAM)
  ///
  /// Default: 81 (MJPEG stream endpoint)
  static const int httpServerPort = 81;

  /// Live Stream Path
  ///
  /// Default: '/stream' (common ESP32-CAM endpoint)
  static const String liveStreamPath = '/stream';

  /// SharedPreferences key for storing Robot IP address
  static const String robotIpStorageKey = 'robot_ip';

  /// SharedPreferences key for storing Stream IP address
  static const String streamIpStorageKey = 'stream_ip';

  /// Get saved Robot IP address from SharedPreferences
  ///
  /// Returns saved IP if available, otherwise returns default Robot IP
  static Future<String> getRobotIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString(robotIpStorageKey);
    return savedIp ?? defaultRobotIp;
  }

  /// Get saved Stream IP address from SharedPreferences
  ///
  /// Returns saved IP if available, otherwise returns default Stream IP
  static Future<String> getStreamIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString(streamIpStorageKey);
    return savedIp ?? defaultStreamIp;
  }

  /// Save Robot IP address to SharedPreferences
  static Future<void> saveRobotIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(robotIpStorageKey, ip);
  }

  /// Save Stream IP address to SharedPreferences
  static Future<void> saveStreamIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(streamIpStorageKey, ip);
  }

  /// Get WebSocket URL with saved Robot IP address
  ///
  /// Returns: ws://<ROBOT_IP>:81
  static Future<String> getWebSocketUrl() async {
    final ip = await getRobotIp();
    return 'ws://$ip:$webSocketPort';
  }

  /// Get Live Stream URL with saved Stream IP address
  ///
  /// Returns: http://<STREAM_IP>:81/stream
  static Future<String> getLiveStreamUrl() async {
    final ip = await getStreamIp();
    return 'http://$ip:$httpServerPort$liveStreamPath';
  }

  /// Auto-reconnect enabled
  static const bool autoReconnect = true;

  /// Reconnect delay in seconds
  static const int reconnectDelaySeconds = 3;
}

/// Legacy alias for backward compatibility
@Deprecated('Use NetworkConfig instead')
class WebSocketConfig {
  static const String defaultRobotIp = NetworkConfig.defaultRobotIp;
  static const int robotPort = NetworkConfig.webSocketPort;
  static const String ipStorageKey = NetworkConfig.robotIpStorageKey;

  static Future<String> getSavedIp() => NetworkConfig.getRobotIp();
  static String get websocketUrl =>
      'ws://${NetworkConfig.defaultRobotIp}:${NetworkConfig.webSocketPort}';
  static Future<String> getWebsocketUrl() => NetworkConfig.getWebSocketUrl();

  static const bool autoReconnect = NetworkConfig.autoReconnect;
  static const int reconnectDelaySeconds = NetworkConfig.reconnectDelaySeconds;
}
