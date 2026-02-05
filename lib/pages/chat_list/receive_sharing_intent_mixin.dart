import 'package:app_links/app_links.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/event/twake_event_types.dart';
import 'package:fluffychat/presentation/extensions/shared_media_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/layouts/agruments/receive_content_args.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

mixin ReceiveSharingIntentMixin<T extends StatefulWidget> on State<T> {
  MatrixState get matrixState;

  StreamSubscription? intentFileStreamSubscription;

  StreamSubscription? intentUriStreamSubscription;

  /// Cached shared media files (last-write-wins among file sources)
  /// Both file and URI caches can have values simultaneously
  List<SharedMediaFile>? _cachedSharedMediaFiles;

  /// Cached shared URI (last-write-wins among URI sources)
  /// Both file and URI caches can have values simultaneously
  String? _cachedSharedUri;

  /// Completer to ensure setupSharingIntentStreams completes before
  /// processCachedSharingIntents processes the cached values.
  /// Prevents race condition when app is opened from terminated state.
  Completer<void>? _setupCompleter;

  bool _intentOpenApp(String text) {
    return text.contains('twake.chat://openApp');
  }

  Future<void> _processIncomingSharedFiles(List<SharedMediaFile> files) async {
    Logs().d('ReceiveSharingIntentMixin::_processIncomingSharedFiles: $files');
    if (files.isEmpty) return;
    if (files.length == 1 &&
        (files.first.isAndroidText() || files.first.isIOSTextAndUrl())) {
      Logs().d('Received text: ${files.first.path}');
      _processIncomingSharedText(files.first.path);
      return;
    }
    matrixState.shareContentList = await Future.wait(
      files.map((sharedMediaFile) async {
        final file = await sharedMediaFile.toMatrixFile();
        Logs().d(
          'ReceiveSharingIntentMixin::_processIncomingSharedFiles: Size ${file.size}',
        );
        return {'msgtype': TwakeEventTypes.shareFileEventType, 'file': file};
      }),
    );
    openSharePage();
  }

  void openSharePage() {
    if (TwakeApp.isCurrentPageIsNotRooms()) {
      return;
    }
    if (TwakeApp.isCurrentPageIsInRooms()) {
      TwakeApp.router.go(
        '/rooms',
        extra: ReceiveContentArgs(
          newActiveClient: matrixState.client,
          activeDestination: AdaptiveDestinationEnum.rooms,
        ),
      );
    }

    TwakeApp.router.push('/rooms/share');
  }

  void _processIncomingSharedText(String? text) {
    if (text == null) return;
    if (_intentOpenApp(text)) {
      return;
    }
    if (text.toLowerCase().startsWith(AppConfig.deepLinkPrefix) ||
        text.toLowerCase().startsWith(AppConfig.inviteLinkPrefix) ||
        (text.toLowerCase().startsWith(AppConfig.schemePrefix) &&
            !RegExp(r'\s').hasMatch(text))) {
      return _processIncomingUris(text);
    }
    matrixState.shareContent = {'msgtype': 'm.text', 'body': text};
    openSharePage();
  }

  void _processIncomingUris(String? text) {
    Logs().d("ReceiveSharingIntentMixin: _processIncomingUris: $text");
    if (text == null) return;
    if (_intentOpenApp(text)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UrlLauncher(TwakeApp.routerKey.currentContext!, url: text).launchUrl();
    });
  }

  void _clearPendingSharedFiles() {
    matrixState.shareContentList = null;
    matrixState.shareContent = null;
  }

  /// Sets up stream listeners and fetches initial sharing intents
  /// Called immediately on app initialization
  ///
  /// Stream behavior:
  /// - If already synced (waitForFirstSync = true): process immediately
  /// - Otherwise: cache for processing after sync completes
  ///
  /// Caching uses last-write-wins:
  /// - Latest file overwrites previous file cache
  /// - Latest URI overwrites previous URI cache
  /// - File and URI caches are independent
  ///
  /// IMPORTANT: This method uses a Completer to ensure processCachedSharingIntents()
  /// waits for setup to complete. This prevents a race condition where sync completes
  /// and processCachedSharingIntents() is called before initial intents are cached.
  Future<void> setupSharingIntentStreams() async {
    if (!PlatformInfos.isMobile) return;

    // Initialize completer to coordinate with processCachedSharingIntents
    _setupCompleter = Completer<void>();

    Logs().d(
      'ReceiveSharingIntentMixin::setupSharingIntentStreams: Setting up streams and caching initial values',
    );

    // Set up file stream - process immediately if synced, otherwise cache
    intentFileStreamSubscription?.cancel();
    intentFileStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) async {
        if (files.isEmpty) return;

        Logs().d(
          'ReceiveSharingIntentMixin::setupSharingIntentStreams: File stream received ${files.length} files',
        );

        // If already synced, process immediately
        if (matrixState.waitForFirstSync) {
          Logs().d(
            'ReceiveSharingIntentMixin::setupSharingIntentStreams: Already synced, processing files immediately',
          );
          await _processIncomingSharedFiles(files);
        } else {
          // Otherwise cache for processing after sync
          Logs().d(
            'ReceiveSharingIntentMixin::setupSharingIntentStreams: Not synced yet, caching files',
          );
          _cachedSharedMediaFiles = files;
        }
      },
      onError: (error, stackTrace) {
        Logs().wtf(
          'ReceiveSharingIntentMixin::setupSharingIntentStreams: Media stream error',
          error,
          stackTrace,
        );
      },
    );

    // Set up URI stream - process immediately if synced, otherwise cache
    final appLinks = AppLinks();
    intentUriStreamSubscription?.cancel();
    intentUriStreamSubscription = appLinks.stringLinkStream.listen(
      (uri) {
        if (_intentOpenApp(uri)) return;

        Logs().d(
          'ReceiveSharingIntentMixin::setupSharingIntentStreams: URI stream received $uri',
        );

        // If already synced, process immediately
        if (matrixState.waitForFirstSync) {
          Logs().d(
            'ReceiveSharingIntentMixin::setupSharingIntentStreams: Already synced, processing URI immediately',
          );
          _processIncomingUris(uri);
        } else {
          // Otherwise cache for processing after sync
          Logs().d(
            'ReceiveSharingIntentMixin::setupSharingIntentStreams: Not synced yet, caching URI',
          );
          _cachedSharedUri = uri;
        }
      },
      onError: (error, stackTrace) {
        Logs().wtf(
          'ReceiveSharingIntentMixin::setupSharingIntentStreams: URI stream error',
          error,
          stackTrace,
        );
      },
    );

    try {
      // Get and cache initial media - MUST await to prevent race condition
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      Logs().d(
        'ReceiveSharingIntentMixin::setupSharingIntentStreams: Initial media received ${files.length} files, caching',
      );
      if (files.isNotEmpty) {
        _cachedSharedMediaFiles = files;
      }
      ReceiveSharingIntent.instance.reset();

      // Get and cache initial link - MUST await to prevent race condition
      final uri = await appLinks.getInitialLinkString();
      Logs().d(
        'ReceiveSharingIntentMixin::setupSharingIntentStreams: Initial link received $uri, caching',
      );
      if (uri != null && !_intentOpenApp(uri)) {
        _cachedSharedUri = uri;
      }
    } catch (e, stackTrace) {
      Logs().wtf(
        'ReceiveSharingIntentMixin::setupSharingIntentStreams: Error fetching initial intents',
        e,
        stackTrace,
      );
    } finally {
      // Complete the setup completer to signal processCachedSharingIntents can proceed
      if (_setupCompleter != null && !_setupCompleter!.isCompleted) {
        _setupCompleter!.complete();
        Logs().d(
          'ReceiveSharingIntentMixin::setupSharingIntentStreams: Setup complete, completer signaled',
        );
      }
    }
  }

  /// Processes cached sharing intents after _trySync completes
  /// Processes both files and URIs (they don't conflict)
  ///
  /// IMPORTANT: This method waits for setupSharingIntentStreams to complete
  /// via the _setupCompleter to prevent race conditions where this is called
  /// before initial intents are cached.
  Future<void> processCachedSharingIntents() async {
    if (!PlatformInfos.isMobile) return;

    // Wait for setup to complete before processing cached values
    if (_setupCompleter == null) {
      Logs().d(
        'ReceiveSharingIntentMixin::processCachedSharingIntents: No setup completer, skipping wait',
      );
    } else if (!_setupCompleter!.isCompleted) {
      Logs().d(
        'ReceiveSharingIntentMixin::processCachedSharingIntents: Waiting for setup to complete',
      );
      await _setupCompleter!.future;
    }

    Logs().d(
      'ReceiveSharingIntentMixin::processCachedSharingIntents: Processing cached intents',
    );

    _clearPendingSharedFiles();

    // Process cached files if any
    if (_cachedSharedMediaFiles != null) {
      Logs().d(
        'ReceiveSharingIntentMixin::processCachedSharingIntents: Processing ${_cachedSharedMediaFiles!.length} cached files',
      );
      try {
        await _processIncomingSharedFiles(_cachedSharedMediaFiles!);
      } catch (e, stackTrace) {
        Logs().wtf(
          'ReceiveSharingIntentMixin::processCachedSharingIntents: Error processing cached files',
          e,
          stackTrace,
        );
      } finally {
        _cachedSharedMediaFiles = null;
      }
    }

    // Process cached URI if any (can happen simultaneously with files)
    if (_cachedSharedUri != null) {
      Logs().d(
        'ReceiveSharingIntentMixin::processCachedSharingIntents: Processing cached URI',
      );
      try {
        _processIncomingUris(_cachedSharedUri);
      } catch (e, stackTrace) {
        Logs().wtf(
          'ReceiveSharingIntentMixin::processCachedSharingIntents: Error processing cached URI',
          e,
          stackTrace,
        );
      } finally {
        _cachedSharedUri = null;
      }
    }
  }
}
