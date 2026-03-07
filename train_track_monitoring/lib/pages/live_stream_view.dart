import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:train_track_monitoring/config/websocket_config.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Embedded live stream widget (WebView).
///
/// This widget is designed for MJPEG streams commonly hosted by ESP32-based
/// camera modules. MJPEG streams may keep an HTTP connection open indefinitely,
/// so this implementation:
/// - Treats the stream as "loaded" after a progress threshold.
/// - Uses a timeout to surface connectivity problems.
/// - Periodically reloads to keep the stream alive.
/// - Automatically retries after transient failures.
///
/// The stream URL is now loaded dynamically from SharedPreferences.
/// Use the "Set IP Address" option in the drawer to configure the ESP32 IP.
///
/// @deprecated - Use NetworkConfig.getLiveStreamUrl() instead
/// Note: Stream uses ESP32-CAM IP, Robot control uses separate Robot ESP32 IP
const String kLiveStreamUrl =
    'http://${NetworkConfig.defaultStreamIp}:${NetworkConfig.httpServerPort}${NetworkConfig.liveStreamPath}';

/// Max time to wait for an initial page load before showing an error.
const Duration _kLoadTimeout = Duration(seconds: 20);

// MJPEG streams often keep the HTTP connection open forever, so the WebView
// may never report 100% progress. We treat the stream as "started" once the
// page reaches a reasonable progress threshold.
const int _kConsiderLoadedAtProgress = 35;

// Many ESP32/MJPEG servers may stop sending after some time (Wi‑Fi sleep,
// server watchdog, router NAT, etc.). Periodically reloading helps keep the
// stream alive.
const Duration _kAutoReloadInterval = Duration(minutes: 2);

// If the stream fails, automatically retry after a short delay.
const Duration _kAutoRetryDelay = Duration(seconds: 2);

/// A reusable widget that displays a WebView-based live stream.
///
/// The public [LiveStreamViewState] exposes [start] and [stop] so a parent widget
/// can control when streaming begins.
class LiveStreamView extends StatefulWidget {
  const LiveStreamView({super.key, this.autoStart = false, this.height = 220});

  /// If true, starts loading immediately.
  final bool autoStart;

  /// Height of the embedded player area.
  final double height;

  @override
  State<LiveStreamView> createState() => LiveStreamViewState();
}

/// State for [LiveStreamView].
///
/// State management logic:
/// - [_started] controls whether the WebView is shown.
/// - [_isLoading]/[_progress] drive the loading overlay.
/// - [_errorMessage] triggers an error UI with a retry button.
///
/// Stream handling logic:
/// - Uses timers to timeout, auto-reload, and auto-retry after failures.
/// - Uses WebView navigation callbacks to update UI state.
class LiveStreamViewState extends State<LiveStreamView> {
  /// Global list of active instances for IP change notification
  static final List<LiveStreamViewState> _activeInstances = [];

  /// Notify all active instances that IP has changed
  static void notifyIpChanged() {
    for (final instance in _activeInstances) {
      instance._handleIpChanged();
    }
  }

  /// Exposes whether the stream has been started to parent widgets.
  bool get isStreaming => _started;

  /// WebView controller used to load/reload the MJPEG URL.
  late final WebViewController _controller;

  /// Whether streaming mode is enabled (controls whether WebView is displayed).
  bool _started = false;

  /// Whether the WebView is currently attempting to load content.
  bool _isLoading = false;

  /// Current page load progress as reported by the WebView (0-100).
  int _progress = 0;

  /// Most recent error message to display; when non-null, the error overlay is shown.
  String? _errorMessage;

  /// Timer used to enforce an initial load timeout.
  Timer? _timeoutTimer;

  /// Timer used to periodically reload the stream to keep the connection active.
  Timer? _autoReloadTimer;

  /// Timer used to retry loading after a transient error.
  Timer? _autoRetryTimer;

  /// Cached stream URL loaded from SharedPreferences
  String? _cachedStreamUrl;

  /// Returns the configured stream URL as a [Uri], ensuring it has a scheme.
  Future<Uri> get _uriToLoad async {
    // Use cached URL if available, otherwise load from config
    _cachedStreamUrl ??= await NetworkConfig.getLiveStreamUrl();
    final raw = _cachedStreamUrl!.trim();
    final withScheme = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'http://$raw';
    return Uri.parse(withScheme);
  }

  /// Handle IP address change notification
  void _handleIpChanged() {
    // Clear cached URL to force reload from SharedPreferences
    _cachedStreamUrl = null;

    // If streaming is active, restart with new IP
    if (_started) {
      stop();
      // Delay restart to allow proper cleanup
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          start();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Register this instance for IP change notifications
    _activeInstances.add(this);

    // Platform-specific WebView configuration.
    //
    // These params enable inline playback on iOS and configure Android's
    // platform controller when running on Android.
    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      // MJPEG streams typically do not require JS, but unrestricted mode avoids
      // issues with embedded stream pages.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Called when navigation begins; used to show loading UI and start the timeout.
          onPageStarted: (url) {
            _startLoading(url: url);
          },
          // Called during navigation; used to update progress and hide loading UI
          // once a reasonable threshold is reached.
          onProgress: (progress) {
            if (!mounted) return;
            final p = progress.clamp(0, 100);
            setState(() {
              _progress = p;

              // For MJPEG/long-polling streams, progress often never reaches 100.
              // Stop showing the loader after a small threshold.
              if (p >= _kConsiderLoadedAtProgress) {
                _isLoading = false;
              }
            });
          },
          // Called when navigation completes; some streams may never finish.
          onPageFinished: (_) {
            // Some streams may never report "finished"; but if they do, treat it as loaded.
            _stopLoading();
          },
          // Called for HTTP-level errors.
          onHttpError: (HttpResponseError error) {
            debugPrint(
              '[LiveStreamView] HTTP error: statusCode=${error.response?.statusCode} url=${error.request?.uri}',
            );
            _showError(
              'Server error (HTTP ${error.response?.statusCode ?? 'unknown'}).\n'
              'Check ESP32 IP address in settings.',
            );
            _scheduleAutoRetry();
          },
          // Called for lower-level resource errors (DNS, connection, etc.).
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[LiveStreamView] Web error: code=${error.errorCode} type=${error.errorType} desc=${error.description} url=${error.url}',
            );
            _showError('Could not load stream.\nReason: ${error.description}');
            _scheduleAutoRetry();
          },
        ),
      );

    // Android-specific tuning.
    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      platformController.setMediaPlaybackRequiresUserGesture(false);
    }

    if (widget.autoStart) {
      // delay to allow widget to mount and show UI first
      WidgetsBinding.instance.addPostFrameCallback((_) => start());
    }
  }

  /// Call this from outside (RoboticArmControlPage button) to begin streaming.
  ///
  /// If the stream is already started, this performs a reload instead.
  Future<void> start() async {
    if (_started) {
      await reload();
      return;
    }
    _started = true;

    // Starts periodic reloads to reduce long-lived connection issues.
    _startAutoReload();

    // Loads the stream URL into the WebView.
    await _load();
  }

  /// Starts/restarts the periodic auto-reload timer.
  ///
  /// Auto-reload helps keep MJPEG sessions alive across unstable networks.
  void _startAutoReload() {
    _autoReloadTimer?.cancel();
    _autoReloadTimer = Timer.periodic(_kAutoReloadInterval, (_) async {
      if (!mounted) return;
      if (!_started) return;
      // If user is currently seeing an error, let auto-retry handle it.
      if (_errorMessage != null) return;

      debugPrint('[LiveStreamView] Auto reload');
      await reload();
    });
  }

  /// Schedules a one-shot retry load after a failure.
  ///
  /// This is used when a transient error occurs (e.g., Wi-Fi hiccup).
  void _scheduleAutoRetry() {
    _autoRetryTimer?.cancel();
    _autoRetryTimer = Timer(_kAutoRetryDelay, () async {
      if (!mounted) return;
      if (!_started) return;
      debugPrint('[LiveStreamView] Auto retry');
      await _load();
    });
  }

  /// Reloads the WebView content if streaming has started.
  ///
  /// Falls back to a fresh load if the platform reload fails.
  Future<void> reload() async {
    if (!_started) return;
    try {
      await _controller.reload();
    } catch (e) {
      // fallback
      await _load();
    }
  }

  /// Stops the stream and frees resources (best effort).
  ///
  /// This cancels auto-reload/auto-retry and loads a blank page.
  Future<void> stop() async {
    if (!_started) return;

    _timeoutTimer?.cancel();
    _autoReloadTimer?.cancel();
    _autoRetryTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _started = false;
      _isLoading = false;
      _progress = 0;
      _errorMessage = null;
    });

    // Best-effort: clear the WebView content.
    // (Some platforms may ignore about:blank, but usually it stops the stream.)
    try {
      await _controller.loadHtmlString('');
    } catch (_) {
      // ignore
    }
  }

  /// Updates state to reflect that loading has started and arms the timeout.
  void _startLoading({String? url}) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_kLoadTimeout, () {
      if (!mounted) return;
      if (_errorMessage != null) return;
      if (!_isLoading) return;
      _showError('Loading timed out. Check network and ESP32 IP: ${url ?? ""}');
    });

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _progress = 0;
      _errorMessage = null;
    });
  }

  /// Clears loading indicators after the WebView reports completion.
  void _stopLoading() {
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _progress = 100;
    });
  }

  /// Stores an error message and switches the UI into an error state.
  void _showError(String message) {
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  /// Loads the configured stream URI into the WebView.
  ///
  /// This is the main "start streaming" operation and is used by start/retry.
  Future<void> _load() async {
    final uri = await _uriToLoad;
    _startLoading(url: uri.toString());

    try {
      // WebView API call: performs a navigation request to the stream URL.
      await _controller.loadRequest(uri);
    } catch (e, st) {
      debugPrint('[LiveStreamView] loadRequest exception: $e\n$st');
      _showError('Failed to load: $e');
    }
  }

  @override
  void dispose() {
    // Unregister this instance from IP change notifications
    _activeInstances.remove(this);

    // Stream/timer handling cleanup to avoid leaks when the widget is removed.
    _timeoutTimer?.cancel();
    _autoReloadTimer?.cancel();
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget structure:
    // - WebView when started
    // - Loading overlay while fetching initial content
    // - Error overlay with a retry button
    // - Debug host label in debug mode
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black12,
            border: Border.all(color: Colors.black12),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: _started
                    ? WebViewWidget(controller: _controller)
                    : const Center(child: Text('Press Live Stream to start')),
              ),

              // Loading overlay shown until the stream is considered "loaded".
              if (_started && _isLoading && _errorMessage == null)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0x33FFFFFF),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text('Loading… $_progress%'),
                        ],
                      ),
                    ),
                  ),
                ),

              // Error overlay shown when the last load attempt failed.
              if (_errorMessage != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off, size: 36),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              // Allows the user to manually restart the load.
                              onPressed: start,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Debug-only hint to confirm which host is being used.
              if (kDebugMode)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: FutureBuilder<Uri>(
                    future: _uriToLoad,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            snapshot.data!.host,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
