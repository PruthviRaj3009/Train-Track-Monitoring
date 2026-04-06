import 'package:flutter/material.dart';
import 'package:train_track_monitoring/pages/arm_control_panel.dart';
import 'package:train_track_monitoring/pages/live_stream_view.dart';
import 'package:train_track_monitoring/services/websocket_service.dart';
import 'dart:developer';
// import 'package:loginpage/pages/arm_control_panel.dart';
// import 'package:loginpage/pages/live_stream_view.dart';
// import 'package:loginpage/services/websocket_service.dart';

/// Main landing page after authentication.
///
/// Provides tab navigation, logout handling, and embeds the live stream and
/// control panel on the Home tab.
class RoboticArmControlPage extends StatefulWidget {
  const RoboticArmControlPage({super.key});

  @override
  State<RoboticArmControlPage> createState() => _RoboticArmControlPageState();
}

/// State for [RoboticArmControlPage].
///
/// Manages the selected tab index and coordinates start/stop control for the
/// embedded [LiveStreamView].
class _RoboticArmControlPageState extends State<RoboticArmControlPage> {
  /// Key used to access [LiveStreamViewState] methods (start/stop) from a button
  /// in this parent widget.
  final _liveStreamKey = GlobalKey<LiveStreamViewState>();

  /// Cached streaming state to drive the button label and action.
  ///
  /// This is kept in sync with the child widget state when possible.
  bool _isStreaming = false;

  /// WebSocket service instance for robot communication (singleton)
  final _websocketService = WebSocketService.instance;

  @override
  void initState() {
    super.initState();

    log('[ARM_CONTROL] Initializing robotic arm control page');
    // Retain reference to singleton WebSocket service
    _websocketService.retain();

    // Keep local button state in sync once the stream widget is mounted.
    //
    // This post-frame callback runs after the first build so the GlobalKey has a
    // chance to resolve the child's state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stream = _liveStreamKey.currentState;
      if (!mounted || stream == null) return;
      setState(() => _isStreaming = stream.isStreaming);
    });
  }

  @override
  void dispose() {
    log('[ARM_CONTROL] Disposing robotic arm control page');
    // Release reference (will only disconnect if no other pages using it)
    _websocketService.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFF2F5FA), child: _homeTab(context));
  }

  /// Builds the primary Home tab.
  ///
  /// Widget structure:
  /// - Embedded live stream view
  /// - Start/Stop button that controls the child WebView stream
  /// - Scrollable arm control panel
  Widget _homeTab(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live stream area (embedded on Home page)
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0B1E3A).withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B1E3A).withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LiveStreamView(
                  // GlobalKey enables calling start/stop on the child state.
                  key: _liveStreamKey,
                  autoStart: false,
                  height: 220,
                ),
              ),
            ),
          ),

          // Button below stream view; when clicked it starts the stream.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1E3A),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: const Color(0xFF0B1E3A).withOpacity(0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                onPressed: () async {
                  // Access the child's state to control the stream.
                  final stream = _liveStreamKey.currentState;
                  if (stream == null) return;

                  // Delegates stream start/stop to the WebView widget.
                  if (_isStreaming) {
                    await stream.stop();
                  } else {
                    await stream.start();
                  }

                  if (!mounted) return;

                  // Local state management: refresh button label/state based on
                  // the current child streaming status.
                  setState(() {
                    _isStreaming = stream.isStreaming;
                  });
                },
                child: Text(
                  _isStreaming ? 'Stop Live Stream' : 'Start Live Stream',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Keeps the control panel scrollable while the page uses a Column.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0B1E3A).withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1E3A).withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ArmControlPanel(websocketService: _websocketService),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
