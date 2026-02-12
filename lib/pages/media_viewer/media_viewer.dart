import 'package:fluffychat/pages/media_viewer/media_viewer_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MediaViewer extends StatefulWidget {
  const MediaViewer({super.key, required this.event});

  final Event event;

  @override
  State<MediaViewer> createState() => MediaViewerController();
}

class MediaViewerController extends State<MediaViewer> {
  List<Event> mediaEvents = [];
  String? forwardToken;
  String? backwardToken;
  Direction? loadingMoreDirection;
  ScrollPhysics? scrollPhysics;
  late final PageController pageController;
  final currentPage = ValueNotifier<int>(0);
  final showAppBarAndPreview = ValueNotifier<bool>(true);

  Client? get client {
    if (!context.mounted) return null;

    return Matrix.of(context).client;
  }

  bool get noTokenAvailable => forwardToken == null && backwardToken == null;

  Future<void> initMediaEvents() async {
    final event = widget.event;
    final room = event.room;
    final mustDecrypt = room.encrypted && client?.encryptionEnabled == true;
    try {
      EventContext? initialEventContext;
      try {
        initialEventContext = await client?.getEventContext(
          room.id,
          event.eventId,
          limit: 100,
        );
      } catch (e) {
        Logs().e('initMediaEvents: Error getting event context', e);
      }
      if (initialEventContext == null) return;
      List<Event> initialMediaEvents = [
        ...(initialEventContext.eventsAfter?.reversed.toList() ?? []),
        if (initialEventContext.event != null) initialEventContext.event!,
        ...(initialEventContext.eventsBefore ?? []),
      ].map((matrixEvent) => Event.fromMatrixEvent(matrixEvent, room)).toList();
      if (mustDecrypt) {
        initialMediaEvents = await decryptEvents(initialMediaEvents);
      }
      initialMediaEvents = initialMediaEvents.mediaEventsOnly;
      int loadMoreCount = 0;
      forwardToken = initialEventContext.end;
      backwardToken = initialEventContext.start;

      while (initialMediaEvents.length < 7 &&
          loadMoreCount < 10 &&
          !noTokenAvailable) {
        loadMoreCount++;
        final expandResult = await expandEvents(
          forwardToken: forwardToken,
          backwardToken: backwardToken,
        );
        forwardToken = expandResult.forward?.end;
        backwardToken = expandResult.backward?.end;
        List<Event> forwardEvents =
            expandResult.forward?.chunk
                .map((e) => Event.fromMatrixEvent(e, room))
                .toList() ??
            [];
        List<Event> backwardEvents =
            expandResult.backward?.chunk
                .map((e) => Event.fromMatrixEvent(e, room))
                .toList() ??
            [];
        if (mustDecrypt) {
          final decrypted = await Future.wait([
            decryptEvents(forwardEvents),
            decryptEvents(backwardEvents),
          ]);
          forwardEvents = decrypted[0].mediaEventsOnly;
          backwardEvents = decrypted[1].mediaEventsOnly;
        }
        initialMediaEvents = [
          ...backwardEvents.reversed,
          ...initialMediaEvents,
          ...forwardEvents,
        ];
      }

      setState(() {
        mediaEvents = initialMediaEvents;
      });
      final page = mediaEvents.indexWhere(
        (event) => event.eventId == widget.event.eventId,
      );
      currentPage.value = page;
      pageController.jumpToPage(page);
    } catch (e) {
      Logs().e('init media events error', e);
      return;
    }
  }

  Future<List<Event>> decryptEvents(List<Event> events) async {
    if (client?.encryption == null) return events;

    return await Future.wait(
      events.map((event) async {
        try {
          if (event.type != EventTypes.Encrypted) {
            return event;
          }

          return await client!.encryption!.decryptRoomEvent(event);
        } catch (e) {
          Logs().e('Error decrypting event id ${event.eventId}', e);
          return event;
        }
      }),
    );
  }

  Future<({GetRoomEventsResponse? backward, GetRoomEventsResponse? forward})>
  expandEvents({String? backwardToken, String? forwardToken}) async {
    if (client == null) return (backward: null, forward: null);

    final roomId = widget.event.room.id;
    try {
      final result = await Future.wait([
        if (backwardToken != null)
          client!.getRoomEvents(
            roomId,
            Direction.b,
            limit: 10,
            from: backwardToken,
          ),
        if (forwardToken != null)
          client!.getRoomEvents(
            roomId,
            Direction.f,
            limit: 10,
            from: forwardToken,
          ),
      ]);
      return (
        backward: result.where((e) => e.start == backwardToken).firstOrNull,
        forward: result.where((e) => e.end == forwardToken).firstOrNull,
      );
    } catch (e) {
      Logs().e('expand events error', e);
      return (backward: null, forward: null);
    }
  }

  Future<void> loadMore(Direction direction, {int limit = 10}) async {
    if (client == null ||
        direction == Direction.b && backwardToken == null ||
        direction == Direction.f && forwardToken == null) {
      return;
    }
    setState(() {
      loadingMoreDirection = direction;
    });
    final room = widget.event.room;
    final mustDecrypt = room.encrypted && client!.encryptionEnabled == true;
    final result = await expandEvents(
      backwardToken: direction == Direction.b ? backwardToken : null,
      forwardToken: direction == Direction.f ? forwardToken : null,
    );
    List<Event> loadMoreEvents = direction == Direction.b
        ? result.backward?.chunk
                  .map((e) => Event.fromMatrixEvent(e, room))
                  .toList() ??
              []
        : result.forward?.chunk
                  .map((e) => Event.fromMatrixEvent(e, room))
                  .toList() ??
              [];
    if (mustDecrypt) {
      loadMoreEvents = await decryptEvents(loadMoreEvents);
    }
    loadMoreEvents = loadMoreEvents.mediaEventsOnly;
    if (direction == Direction.b) {
      backwardToken = result.backward?.end;
      mediaEvents = [...mediaEvents, ...loadMoreEvents];
    } else {
      forwardToken = result.forward?.end;
      mediaEvents = [...loadMoreEvents.reversed, ...mediaEvents];
    }
    if (loadMoreEvents.isEmpty) {
      await loadMore(direction, limit: limit - 1);
    }
    loadingMoreDirection = null;
    if (limit == 10) {
      setState(() {});
    }
  }

  void pageChangedListener() {
    if (currentPage.value == -1) return;

    if (mediaEvents[currentPage.value].messageType == MessageTypes.Video) {
      showAppBarAndPreview.value = true;
    }

    if (currentPage.value == 0) {
      loadMore(Direction.f);
    } else if (currentPage.value == mediaEvents.length - 1) {
      loadMore(Direction.b);
    }
  }

  void togglePageViewScroll(bool stopScroll) {
    setState(() {
      scrollPhysics = stopScroll ? const NeverScrollableScrollPhysics() : null;
    });
  }

  @override
  void initState() {
    super.initState();
    mediaEvents = [widget.event];
    pageController = PageController();
    currentPage.addListener(pageChangedListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initMediaEvents();
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    currentPage.removeListener(pageChangedListener);
    currentPage.dispose();
    showAppBarAndPreview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaViewerView(controller: this);
  }
}

extension _ListEventExtension on List<Event> {
  List<Event> get mediaEventsOnly => where((e) => e.isVideoOrImage).toList();
}
