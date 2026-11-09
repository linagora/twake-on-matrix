import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';

/// Top-level function for native isolate-based sync response parsing.
/// Returns a fully constructed [SyncUpdate] since Dart isolates can
/// transfer complex objects without serialization overhead, with the
/// per-thread counters the SDK does not parse.
(SyncUpdate, Map<String, Map<String, ThreadCounts>>) _parseSyncResponseNative(
  Uint8List responseBody,
) {
  final responseString = utf8.decode(responseBody);
  final json = jsonDecode(responseString) as Map<String, Object?>;
  return (SyncUpdate.fromJson(json), parseSyncUnreadThreadNotifications(json));
}

/// Top-level function for web JSON decoding via `compute()`.
/// Returns only the raw [Map] because structured clone (used by web workers)
/// transfers Maps/Lists/primitives efficiently, whereas custom Dart class
/// instances like [SyncUpdate] do not. [SyncUpdate.fromJson] is therefore
/// called on the main thread after the transfer.
Map<String, Object?> _jsonDecodeSyncResponseWeb(Uint8List responseBody) {
  final responseString = utf8.decode(responseBody);
  return jsonDecode(responseString) as Map<String, Object?>;
}

/// A [Client] subclass that offloads the heavy JSON parsing of `/sync`
/// responses to a background isolate / web worker.
///
/// On **native** platforms (iOS, Android, macOS, Linux), the entire parsing
/// pipeline (`utf8.decode` + `jsonDecode` + `SyncUpdate.fromJson`) runs in
/// a background isolate via `compute()`.
///
/// On **web**, only `utf8.decode` + `jsonDecode` (~80% of parsing time) runs
/// via `compute()`. On Flutter Web with WASM, this executes at near-native
/// speed (not in a separate thread). `SyncUpdate.fromJson` remains on the
/// main thread because structured clone cannot transfer custom Dart class
/// instances — only Maps/Lists/primitives pass without overhead.
///
/// ## Maintenance notice
///
/// This override replicates the HTTP request logic from the generated
/// `Api.sync()` in `matrix_api_lite`. If the upstream SDK changes the
/// sync endpoint (new parameters, headers, or path), this override must
/// be updated accordingly. When upgrading the `matrix` SDK dependency,
/// compare the generated `Api.sync()` signature and body with this
/// implementation.
// Validated against matrix SDK 13.0.0 (Api.sync signature unchanged)
class TwakeClient extends Client implements ThreadUnreadStoreOwner {
  @override
  late final ThreadUnreadStore threadUnread = ThreadUnreadStore(client: this);

  /// Thread counters parsed with a sync, held until the SDK has handled it.
  final _pendingThreadCounts =
      Expando<Map<String, Map<String, ThreadCounts>>>();

  TwakeClient(
    super.clientName, {
    required super.database,
    super.legacyDatabaseBuilder,
    super.verificationMethods,
    super.httpClient,
    super.importantStateEvents,
    super.roomPreviewLastEvents,
    super.pinUnreadRooms,
    super.pinInvitedRooms,
    super.requestHistoryOnLimitedTimeline = true,
    super.supportedLoginTypes,
    super.mxidLocalPartFallback,
    super.formatLocalpart,
    super.nativeImplementations,
    super.logLevel,
    super.syncFilter,
    super.defaultNetworkRequestTimeout,
    super.sendTimelineEventTimeout,
    super.customImageResizer,
    super.shareKeysWith,
    super.enableDehydratedDevices,
    super.receiptsPublicByDefault,
    super.onSoftLogout,
    super.typingIndicatorTimeout,
    super.convertLinebreaksInFormatting,
  }) {
    unawaited(threadUnread.restore());
    // The SDK emits onSync once it has handled the sync: the thread counters
    // then land with the room counters and receipts, and a failed sync never
    // applies them.
    onSync.stream.listen((update) {
      final counts = _pendingThreadCounts[update];
      final left = update.rooms?.leave?.keys ?? const <String>[];
      if (counts != null || left.isNotEmpty) {
        threadUnread.apply(
          SyncThreadUpdate(counts: counts ?? const {}, leftRoomIds: left),
        );
      }
    });
    // Thread replies are remembered (they lose their relation once deleted),
    // the user's own make the thread followed (in the store); the messages of
    // the main timeline tell the room has new ones under a thread reply. A
    // gap filled by requestHistory comes on onHistoryEvent. A local echo
    // (sending, error) is neither: only the synced event counts.
    void onSeenEvent(Event event) {
      if (!event.status.isSynced) return;
      if (event.threadRootId == null) {
        threadUnread.rememberMainTimelineEvent(event);
      } else {
        threadUnread.rememberThreadReply(event);
      }
    }

    onTimelineEvent.stream.listen(onSeenEvent);
    onHistoryEvent.stream.listen(onSeenEvent);

    // The SDK adds call events after the given set: a call would mark the
    // room unread.
    roomPreviewLastEvents.removeWhere(CallEventTypes.isCallEvent);
  }

  /// Logs this account's notification device out and removes its recovery
  /// key first: the SDK forgets the user in `clear`, also when the server
  /// invalidated the session.
  @override
  Future<void> clear({
    SessionClearReason reason = SessionClearReason.unspecified,
  }) async {
    // Never let the notification cleanup keep the app session alive.
    await KeychainSharingManager.logoutNotificationSession(this)
        .timeout(const Duration(seconds: 10))
        .catchError(
          (e, s) => Logs().w('Unable to log the NSE device out', e, s),
        );
    await KeychainSharingManager.deleteRecoveryKey(userId: userID);
    await threadUnread.clear();
    return super.clear(reason: reason);
  }

  @override
  Future<SyncUpdate> sync({
    String? filter,
    String? since,
    bool? fullState,
    PresenceType? setPresence,
    int? timeout,
    bool? useStateAfter,
  }) async {
    // Build the request identically to the generated Api.sync().
    final requestUri = Uri(
      path: '_matrix/client/v3/sync',
      queryParameters: {
        if (filter != null) 'filter': filter,
        if (since != null) 'since': since,
        if (fullState != null) 'full_state': fullState.toString(),
        if (setPresence != null) 'set_presence': setPresence.name,
        if (timeout != null) 'timeout': timeout.toString(),
        if (useStateAfter != null) 'use_state_after': useStateAfter.toString(),
      },
    );
    final request = http.Request('GET', baseUri!.resolveUri(requestUri));
    request.headers['authorization'] = 'Bearer ${bearerToken!}';
    final response = await httpClient.send(request);
    final responseBody = await response.stream.toBytes();
    if (response.statusCode != 200) {
      unexpectedResponse(response, responseBody);
    }

    try {
      if (kIsWeb) {
        // On web: run utf8.decode + jsonDecode via compute() (near-native
        // speed on WASM), then call SyncUpdate.fromJson on the main thread.
        final json = await compute(_jsonDecodeSyncResponseWeb, responseBody);
        final update = SyncUpdate.fromJson(json);
        _pendingThreadCounts[update] = parseSyncUnreadThreadNotifications(json);
        return update;
      }

      // On native: offload the entire pipeline to a background isolate.
      final (update, threadCounts) = await compute(
        _parseSyncResponseNative,
        responseBody,
      );
      _pendingThreadCounts[update] = threadCounts;
      return update;
    } catch (e) {
      // Re-throw parsing errors with context so _innerSync's catch chain
      // can distinguish them from network/connection errors.
      throw FormatException('Failed to parse /sync response: $e');
    }
  }
}
