import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:matrix/matrix.dart';

/// Mixin providing reusable logic for filtering and managing events by type.
///
/// This mixin provides utilities to:
/// - Filter events by message type (Image, Video, Audio, File, etc.)
/// - Decrypt encrypted events
/// - Fetch and expand event context with pagination
/// - Load more events in both directions
///
/// Usage:
/// ```dart
/// class MyController with EventFilterMixin {
///   Future<void> loadEvents() async {
///     final context = await getInitialEventContext(
///       client: client,
///       roomId: room.id,
///       eventId: event.eventId,
///       limit: 100,
///     );
///   }
/// }
/// ```
mixin EventFilterMixin {
  /// Filters a list of events to include only image and video events.
  ///
  /// Returns a new list containing only events with messageType of
  /// [MessageTypes.Image] or [MessageTypes.Video].
  List<Event> filterMediaEvents(List<Event> events) {
    return events.where((event) => event.isVideoOrImage).toList();
  }

  /// Filters events by custom message types.
  ///
  /// Allows filtering by multiple message types at once.
  ///
  /// Example:
  /// ```dart
  /// final mediaAndFiles = filterEventsByTypes(
  ///   events,
  ///   [MessageTypes.Image, MessageTypes.Video, MessageTypes.File],
  /// );
  /// ```
  List<Event> filterEventsByTypes(
    List<Event> events,
    List<String> types,
  ) {
    return events.where((event) => types.contains(event.messageType)).toList();
  }

  /// Decrypts a list of encrypted events.
  ///
  /// If encryption is not enabled on the client, returns the original events.
  /// For each encrypted event, attempts to decrypt it using the client's
  /// encryption engine. If decryption fails, logs the error and returns the
  /// original encrypted event.
  ///
  /// Returns a list of decrypted events (or original events if decryption
  /// fails or is not available).
  Future<List<Event>> decryptEvents(
    List<Event> events,
    Client? client,
  ) async {
    if (client?.encryption == null) return events;

    return await Future.wait(
      events.map(
        (event) async {
          try {
            if (event.type != EventTypes.Encrypted) {
              return event;
            }

            return await client!.encryption!.decryptRoomEvent(event);
          } catch (e) {
            Logs().e('Error decrypting event id ${event.eventId}', e);
            return event;
          }
        },
      ),
    );
  }

  /// Fetches the initial event context for a given event.
  ///
  /// Retrieves events before and after the target event from the server.
  /// Returns null if the client is null or if the request fails.
  ///
  /// Parameters:
  /// - [client]: The Matrix client instance
  /// - [roomId]: The room ID
  /// - [eventId]: The target event ID
  /// - [limit]: Maximum number of events to retrieve (default: 100)
  Future<EventContext?> getInitialEventContext({
    required Client? client,
    required String roomId,
    required String eventId,
    int limit = 100,
  }) async {
    if (client == null) return null;

    try {
      return await client.getEventContext(
        roomId,
        eventId,
        limit: limit,
      );
    } catch (e) {
      Logs().e('getInitialEventContext: Error getting event context', e);
      return null;
    }
  }

  /// Converts MatrixEvents to Events for a given room.
  ///
  /// Maps a list of MatrixEvent objects to Event objects.
  List<Event> convertMatrixEventsToEvents(
    List<MatrixEvent> matrixEvents,
    Room room,
  ) {
    return matrixEvents
        .map((matrixEvent) => Event.fromMatrixEvent(matrixEvent, room))
        .toList();
  }

  /// Builds initial event list from event context.
  ///
  /// Combines events before, the target event, and events after from an
  /// EventContext. Returns the events in chronological order (oldest to
  /// newest).
  List<Event> buildInitialEventList(
    EventContext eventContext,
    Room room,
  ) {
    return [
      ...(eventContext.eventsAfter?.reversed.toList() ?? []),
      if (eventContext.event != null) eventContext.event!,
      ...(eventContext.eventsBefore ?? []),
    ].map((matrixEvent) => Event.fromMatrixEvent(matrixEvent, room)).toList();
  }

  /// Expands events by fetching more events in forward and/or backward
  /// directions.
  ///
  /// Fetches events from the server using pagination tokens.
  ///
  /// Parameters:
  /// - [client]: The Matrix client instance
  /// - [roomId]: The room ID
  /// - [backwardToken]: Token for fetching older events
  /// - [forwardToken]: Token for fetching newer events
  /// - [limit]: Number of events to fetch per direction (default: 10)
  ///
  /// Returns a record containing the backward and forward responses.
  Future<
      ({
        GetRoomEventsResponse? backward,
        GetRoomEventsResponse? forward,
      })> expandEvents({
    required Client? client,
    required String roomId,
    String? backwardToken,
    String? forwardToken,
    int limit = 10,
  }) async {
    if (client == null) return (backward: null, forward: null);

    try {
      final result = await Future.wait([
        if (backwardToken != null)
          client.getRoomEvents(
            roomId,
            Direction.b,
            limit: limit,
            from: backwardToken,
          ),
        if (forwardToken != null)
          client.getRoomEvents(
            roomId,
            Direction.f,
            limit: limit,
            from: forwardToken,
          ),
      ]);

      // Use positional indexing since Future.wait preserves order
      GetRoomEventsResponse? backwardResponse;
      GetRoomEventsResponse? forwardResponse;

      if (backwardToken != null && forwardToken != null) {
        // Both tokens: result[0] = backward, result[1] = forward
        backwardResponse = result.isNotEmpty ? result[0] : null;
        forwardResponse = result.length > 1 ? result[1] : null;
      } else if (backwardToken != null) {
        // Only backward: result[0] = backward
        backwardResponse = result.isNotEmpty ? result[0] : null;
      } else if (forwardToken != null) {
        // Only forward: result[0] = forward
        forwardResponse = result.isNotEmpty ? result[0] : null;
      }

      return (backward: backwardResponse, forward: forwardResponse);
    } catch (e) {
      Logs().e('expandEvents: Error expanding events', e);
      return (backward: null, forward: null);
    }
  }

  /// Loads and processes initial events with automatic expansion.
  ///
  /// This method:
  /// 1. Fetches the initial event context
  /// 2. Builds the initial event list
  /// 3. Decrypts events if needed
  /// 4. Filters events by specified message types
  /// 5. Automatically expands to get at least [minEventsTarget] events
  ///
  /// Parameters:
  /// - [messageTypes]: List of message types to filter. If null, filters for
  ///   media events (images and videos) by default.
  ///
  /// Returns a record containing the filtered events and pagination tokens.
  Future<
      ({
        List<Event> events,
        String? forwardToken,
        String? backwardToken,
      })> initMediaEvents({
    required Client? client,
    required Room room,
    required String eventId,
    List<String>? messageTypes,
    int initialLimit = 100,
    int minEventsTarget = 7,
    int maxExpandIterations = 10,
    int expandLimit = 10,
  }) async {
    if (client == null) {
      return (events: <Event>[], forwardToken: null, backwardToken: null);
    }

    final mustDecrypt = room.encrypted && client.encryptionEnabled == true;

    try {
      final initialEventContext = await getInitialEventContext(
        client: client,
        roomId: room.id,
        eventId: eventId,
        limit: initialLimit,
      );

      if (initialEventContext == null) {
        return (events: <Event>[], forwardToken: null, backwardToken: null);
      }

      List<Event> initialFilteredEvents =
          buildInitialEventList(initialEventContext, room);

      if (mustDecrypt) {
        initialFilteredEvents =
            await decryptEvents(initialFilteredEvents, client);
      }

      initialFilteredEvents = messageTypes != null
          ? filterEventsByTypes(initialFilteredEvents, messageTypes)
          : filterMediaEvents(initialFilteredEvents);

      String? forwardToken = initialEventContext.end;
      String? backwardToken = initialEventContext.start;
      int loadMoreCount = 0;

      // Expand until we have enough events or run out of tokens
      while (initialFilteredEvents.length < minEventsTarget &&
          loadMoreCount < maxExpandIterations &&
          (forwardToken != null || backwardToken != null)) {
        loadMoreCount++;

        final expandResult = await expandEvents(
          client: client,
          roomId: room.id,
          forwardToken: forwardToken,
          backwardToken: backwardToken,
          limit: expandLimit,
        );

        forwardToken = expandResult.forward?.end;
        backwardToken = expandResult.backward?.end;

        List<Event> forwardEvents = convertMatrixEventsToEvents(
          expandResult.forward?.chunk ?? [],
          room,
        );

        List<Event> backwardEvents = convertMatrixEventsToEvents(
          expandResult.backward?.chunk ?? [],
          room,
        );

        if (mustDecrypt) {
          final decrypted = await Future.wait([
            decryptEvents(forwardEvents, client),
            decryptEvents(backwardEvents, client),
          ]);
          forwardEvents = decrypted[0];
          backwardEvents = decrypted[1];
        }

        initialFilteredEvents = [
          ...(messageTypes != null
              ? filterEventsByTypes(
                  backwardEvents.reversed.toList(),
                  messageTypes,
                )
              : filterMediaEvents(backwardEvents.reversed.toList())),
          ...initialFilteredEvents,
          ...(messageTypes != null
              ? filterEventsByTypes(
                  forwardEvents.reversed.toList(),
                  messageTypes,
                )
              : filterMediaEvents(forwardEvents.reversed.toList())),
        ];
      }

      return (
        events: initialFilteredEvents,
        forwardToken: forwardToken,
        backwardToken: backwardToken,
      );
    } catch (e) {
      Logs().e('initMediaEvents: Error initializing events', e);
      return (events: <Event>[], forwardToken: null, backwardToken: null);
    }
  }

  /// Gets audio events from the clicked event onwards for playlist.
  ///
  /// Returns all audio events from the clicked event onwards (for auto-play).
  /// Events are returned in chronological order from clicked to newest.
  ///
  /// Example:
  /// ```dart
  /// // If audioEvents = [a, b, c, d, e] (chronological order)
  /// // and user clicks on c
  /// final result = getAudioEventsUpToClicked(audioEvents, clickedEvent);
  /// // returns [c, d, e] (for sequential playback)
  /// ```
  ///
  /// Parameters:
  /// - [audioEvents]: The list of audio events in chronological order
  /// - [clickedEvent]: The event that was clicked
  ///
  /// Returns a list of audio events from the clicked position onwards.
  List<Event> getAudioEventsUpToClicked(
    List<Event> audioEvents,
    Event clickedEvent,
  ) {
    final reversedEvents = audioEvents.reversed.toList();
    final clickedIndex = reversedEvents.indexWhere(
      (event) => event.eventId == clickedEvent.eventId,
    );

    if (clickedIndex == -1) {
      return [];
    }

    // Get clicked event's timestamp
    final clickedTimestamp = clickedEvent.originServerTs.millisecondsSinceEpoch;

    // Return from clicked event onwards for sequential playback
    final eventsFromClicked = reversedEvents.sublist(clickedIndex);

    // Filter by timestamp: only keep clicked event + events with newer timestamps
    final filteredByTimestamp = eventsFromClicked.where((event) {
      return event.originServerTs.millisecondsSinceEpoch >= clickedTimestamp;
    }).toList();

    return filteredByTimestamp;
  }

  /// Loads and processes initial audio events with automatic expansion.
  ///
  /// Similar to [initMediaEvents] but specifically for audio files.
  /// Returns audio events up to and including the clicked event.
  ///
  /// Example:
  /// ```dart
  /// final result = await initAudioEventsUpToClicked(
  ///   client: client,
  ///   room: room,
  ///   clickedEvent: event,
  /// );
  /// ```
  Future<
      ({
        List<Event> events,
        String? forwardToken,
        String? backwardToken,
      })> initAudioEventsUpToClicked({
    required Client? client,
    required Room room,
    required Event clickedEvent,
    int initialLimit = 100,
    int minEventsTarget = 20,
    int maxExpandIterations = 10,
    int expandLimit = 10,
  }) async {
    // First, get all audio events including and after the clicked event
    final result = await initMediaEvents(
      client: client,
      room: room,
      eventId: clickedEvent.eventId,
      messageTypes: [MessageTypes.Audio],
      initialLimit: initialLimit,
      minEventsTarget: minEventsTarget,
      maxExpandIterations: maxExpandIterations,
      expandLimit: expandLimit,
    );

    // Find the clicked event and return only events up to it
    final filteredEvents = getAudioEventsUpToClicked(
      result.events,
      clickedEvent,
    );

    return (
      events: filteredEvents,
      forwardToken: result.forwardToken,
      backwardToken: result.backwardToken,
    );
  }
}
