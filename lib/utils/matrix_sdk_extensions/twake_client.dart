import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

/// Top-level function for native isolate-based sync response parsing.
/// Returns a fully constructed [SyncUpdate] since Dart isolates can
/// transfer complex objects without serialization overhead.
SyncUpdate _parseSyncResponseNative(Uint8List responseBody) {
  final responseString = utf8.decode(responseBody);
  final json = jsonDecode(responseString);
  return SyncUpdate.fromJson(json as Map<String, Object?>);
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
// Validated against matrix SDK ^6.0.0
class TwakeClient extends Client {
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
    super.requestHistoryOnLimitedTimeline,
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
  });

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
        return SyncUpdate.fromJson(json);
      }

      // On native: offload the entire pipeline to a background isolate.
      return await compute(_parseSyncResponseNative, responseBody);
    } catch (e) {
      // Re-throw parsing errors with context so _innerSync's catch chain
      // can distinguish them from network/connection errors.
      throw FormatException('Failed to parse /sync response: $e');
    }
  }
}
