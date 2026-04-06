import 'package:flutter/material.dart';
import 'package:train_track_monitoring/models/robot_control_message.dart';
import 'package:train_track_monitoring/services/websocket_service.dart';
import 'dart:developer';

/// UI panel for controlling a robotic arm.
///
/// Exposes joint positions and speed as sliders. Sends control messages
/// via WebSocket when values change or movement buttons are pressed.
class ArmControlPanel extends StatefulWidget {
  final WebSocketService websocketService;

  const ArmControlPanel({super.key, required this.websocketService});

  @override
  State<ArmControlPanel> createState() => _ArmControlPanelState();
}

/// State for [ArmControlPanel].
///
/// Stores the current slider values and updates them using [setState] when the
/// user finishes dragging a slider. Sends WebSocket messages on changes.
class _ArmControlPanelState extends State<ArmControlPanel> {
  // Important variables: each represents a servo/joint angle in degrees.
  double grip = 90;
  double wristPitch = 90;
  double wristRoll = 90;
  double elbow = 90;
  double shoulder = 90;
  double waist = 90;

  /// Movement speed (UI value; interpretation is hardware-specific).
  double speed = 50;

  /// Sends current servo positions to the robot via WebSocket.
  void _sendControlMessage() {
    log('[CONTROL_TRIGGERED] Creating control message with values:');
    log(
      '[CONTROL_TRIGGERED]   grip=$grip, wristPitch=$wristPitch, wristRoll=$wristRoll',
    );
    log(
      '[CONTROL_TRIGGERED]   elbow=$elbow, shoulder=$shoulder, waist=$waist, speed=$speed',
    );

    final message = RobotControlMessage.control(
      grip: grip,
      wristPitch: wristPitch,
      wristRoll: wristRoll,
      elbow: elbow,
      shoulder: shoulder,
      waist: waist,
      speed: speed,
    );

    log('[CONTROL_TRIGGERED] Sending control message to WebSocket');
    widget.websocketService.sendMessage(message);
  }

  /// Sends a movement command to the robot.
  void _sendMovementCommand(String command) {
    log(
      '[CONTROL_TRIGGERED] Movement button pressed: ${command.toUpperCase()}',
    );

    final message = RobotControlMessage.movement(command);

    log('[CONTROL_TRIGGERED] Sending movement command to WebSocket');
    widget.websocketService.sendMessage(message);
  }

  /// Builds a labeled slider row.
  ///
  /// Uses [onChangeEnd] to avoid sending continuous updates, which is typically
  /// preferred for robotics control links.
  Widget buildSlider(
    String label,
    double value,
    ValueChanged<double> onEnd, {
    Color color = Colors.orange,
    double max = 180,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: Row(
        children: [
          // LABEL
          SizedBox(
            width: 100, // fixed width for alignment
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),

          // SLIDER
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4, // slimmer slider
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8, // smaller thumb
                ),
              ),
              child: Slider(
                min: 0,
                max: max,
                value: value,
                activeColor: color,
                inactiveColor: Colors.grey.shade400,
                // Intentionally no continuous updates; the value is committed
                // on drag end via [onChangeEnd].
                onChanged: (_) {}, // avoid continuous updates
                onChangeEnd: onEnd, // best for robotics
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widget structure:
    // - Top bar with connection controls (placeholders)
    // - Sliders for each joint and speed
    // - Bottom bar with movement controls (placeholders)
    return Column(
      children: [
        // TOP BAR - Connection controls
        // StreamBuilder<bool>(
        //   stream: widget.websocketService.connectionStream,
        //   initialData: false,
        //   builder: (context, snapshot) {
        //     final isConnected = snapshot.data ?? false;
        //     return Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //       children: [
        //         ElevatedButton(
        //           onPressed: isConnected
        //               ? null
        //               : () => widget.websocketService.connect(),
        //           child: const Text("Connect"),
        //         ),
        //         Text(
        //           isConnected ? "Connected" : "Disconnected",
        //           style: TextStyle(
        //             color: isConnected ? Colors.green : Colors.red,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //         ElevatedButton(
        //           onPressed: isConnected
        //               ? () => widget.websocketService.disconnect()
        //               : null,
        //           child: const Text("Disconnect"),
        //         ),
        //       ],
        //     );
        //   },
        // ),
        StreamBuilder<bool>(
          stream: widget.websocketService.connectionStream,
          initialData: false,
          builder: (context, snapshot) {
            final isConnected = snapshot.data ?? false;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isConnected
                          ? null
                          : () => widget.websocketService.connect(),
                      child: const Text(
                        "Connect",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Flexible(
                    child: Text(
                      isConnected ? "Connected" : "Disconnected",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: isConnected
                          ? () => widget.websocketService.disconnect()
                          : null,
                      child: const Text(
                        "Disconnect",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 5),

        // SLIDERS
        // Local state management: each slider commits its value with setState
        // and sends WebSocket message on change end.
        buildSlider("Grip", grip, (v) {
          log('[CONTROL_TRIGGERED] Grip slider released - new value: $v');
          setState(() => grip = v);
          _sendControlMessage();
        }),
        buildSlider("Wrist Pitch", wristPitch, (v) {
          log(
            '[CONTROL_TRIGGERED] Wrist Pitch slider released - new value: $v',
          );
          setState(() => wristPitch = v);
          _sendControlMessage();
        }),
        buildSlider("Wrist Roll", wristRoll, (v) {
          log('[CONTROL_TRIGGERED] Wrist Roll slider released - new value: $v');
          setState(() => wristRoll = v);
          _sendControlMessage();
        }),
        buildSlider("Elbow", elbow, (v) {
          log('[CONTROL_TRIGGERED] Elbow slider released - new value: $v');
          setState(() => elbow = v);
          _sendControlMessage();
        }),
        buildSlider("Shoulder", shoulder, (v) {
          log('[CONTROL_TRIGGERED] Shoulder slider released - new value: $v');
          setState(() => shoulder = v);
          _sendControlMessage();
        }),
        buildSlider("Waist", waist, (v) {
          log('[CONTROL_TRIGGERED] Waist slider released - new value: $v');
          setState(() => waist = v);
          _sendControlMessage();
        }),
        buildSlider("Speed", speed, (v) {
          log('[CONTROL_TRIGGERED] Speed slider released - new value: $v');
          setState(() => speed = v);
          _sendControlMessage();
        }, color: Colors.red),

        // Placeholder for future preset/position saving support.
        const Text("Positions saved: 0"),

        // BOTTOM BUTTONS - Movement controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => _sendMovementCommand('backward'),
              child: const Text("Backward"),
            ),
            ElevatedButton(
              onPressed: () => _sendMovementCommand('stop'),
              child: const Text("Stop"),
            ),
            ElevatedButton(
              onPressed: () => _sendMovementCommand('forward'),
              child: const Text("Forward"),
            ),
          ],
        ),
      ],
    );
  }
}
