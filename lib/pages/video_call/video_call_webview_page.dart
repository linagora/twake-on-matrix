import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';

/// POC: renders a Meet call inside an in-app WebView instead of launching
/// the system browser. Mobile only — other platforms keep the external
/// browser flow.
class VideoCallWebViewPage extends StatefulWidget {
  final String callUrl;

  const VideoCallWebViewPage({super.key, required this.callUrl});

  static bool get isSupported => PlatformInfos.isMobile;

  /// Opens [callUrl] in-app when supported, otherwise falls back to the
  /// existing external browser behavior.
  static Future<void> open(BuildContext context, String callUrl) async {
    if (!isSupported) {
      UrlLauncher(context, url: callUrl).launchUrl();
      return;
    }
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => VideoCallWebViewPage(callUrl: _withScheme(callUrl)),
        fullscreenDialog: true,
      ),
    );
  }

  /// Call URLs may come without a scheme (e.g. `meet.twake.app/abc-defg-hij`
  /// from the .well-known config) — the WebView silently loads nothing in
  /// that case, so default to https like UrlLauncher does.
  static String _withScheme(String url) =>
      Uri.parse(url).hasScheme ? url : 'https://$url';

  @override
  State<VideoCallWebViewPage> createState() => _VideoCallWebViewPageState();
}

class _VideoCallWebViewPageState extends State<VideoCallWebViewPage> {
  // The WebView can only grant getUserMedia if the app itself holds the
  // native camera/microphone permissions, so request them before loading.
  late final Future<bool> _permissionsGranted = _requestNativePermissions();

  Future<bool> _requestNativePermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    return statuses.values.every((status) => status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder<bool>(
                future: _permissionsGranted,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data != true) {
                    return const _PermissionsDeniedView(
                      onOpenSettings: openAppSettings,
                    );
                  }
                  return InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.callUrl)),
                    initialSettings: InAppWebViewSettings(
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                      iframeAllow: 'camera; microphone',
                      iframeAllowFullscreen: true,
                      // Allows attaching Safari Web Inspector / Chrome DevTools
                      // to debug the embedded call page.
                      isInspectable: kDebugMode,
                    ),
                    onReceivedError: (controller, request, error) {
                      Logs().w(
                        'VideoCallWebView failed to load ${request.url}: '
                        '${error.type} ${error.description}',
                      );
                    },
                    onConsoleMessage: (controller, message) {
                      Logs().i('VideoCallWebView console: ${message.message}');
                    },
                    onPermissionRequest: (controller, request) async {
                      // Native permissions were granted above; forward the
                      // grant to the page (getUserMedia).
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT,
                      );
                    },
                    onCloseWindow: (controller) {
                      if (mounted) Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            // Meet cannot close the native page itself (no postMessage
            // bridge), so keep a floating close button on top.
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: Navigator.of(context).pop,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsDeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _PermissionsDeniedView({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_outlined, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Camera and microphone access is required to join the call.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onOpenSettings,
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}
