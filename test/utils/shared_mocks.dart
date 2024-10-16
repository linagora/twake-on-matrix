import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';

const fakeFilename = "fakeFilename";

class MockRoom extends Mock implements Room {
  @override
  bool operator ==(Object other) => (other is Room && other.id == id);

  @override
  int get hashCode => Object.hashAll([id]);

  @override
  Map<String, MatrixFile> get sendingFilePlaceholders => super.noSuchMethod(
        Invocation.getter(#sendingFilePlaceholders),
        returnValue: <String, MatrixFile>{},
        returnValueForMissingStub: <String, MatrixFile>{},
      );
}

class MockEvent extends Mock implements Event {
  MockEvent(this.fakeRoom);
  final Room fakeRoom;
  static const fakeEventId = "fakeEventId";

  @override
  String get eventId => fakeEventId;

  @override
  Room get room => fakeRoom;

  @override
  Map get infoMap => super.noSuchMethod(
        Invocation.getter(#infoMap),
        returnValue: {},
        returnValueForMissingStub: {},
      );
}

class EventGenerator {
  static Event fileEvent(Room room) => Event(
        content: {
          'body': 'something-important.doc',
          'filename': 'something-important.doc',
          'info': {'mimetype': 'application/msword', 'size': 46144},
          'msgtype': 'm.file',
          'url': 'mxc://example.org/FHyPlCeYUSFFxlgbQYZmoEoe',
        },
        type: 'm.room.message',
        eventId: '\$143273582443PhrSn:example.org',
        senderId: '@example:example.org',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
        room: room,
      );

  static Event imageEvent(Room room) => Event(
        content: {
          'body': 'filename.jpg',
          'info': {'h': 398, 'mimetype': 'image/jpeg', 'size': 31037, 'w': 394},
          'msgtype': 'm.image',
          'url': 'mxc://example.org/JWEIFJgwEIhweiWJE',
        },
        type: 'm.room.message',
        eventId: '\$143273582443PhrSn:example.org',
        senderId: '@example:example.org',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
        room: room,
      );

  static Event videoEvent(Room room) => Event(
        content: {
          'body': 'Gangnam Style',
          'info': {
            'duration': 2140786,
            'h': 320,
            'mimetype': 'video/mp4',
            'size': 1563685,
            'thumbnail_info': {
              'h': 300,
              'mimetype': 'image/jpeg',
              'size': 46144,
              'w': 300,
            },
            'thumbnail_url': 'mxc://example.org/FHyPlCeYUSFFxlgbQYZmoEoe',
            'w': 480,
          },
          'msgtype': 'm.video',
          'url': 'mxc://example.org/a526eYUSFFxlgbQYZmo442',
        },
        type: 'm.room.message',
        eventId: '\$143273582443PhrSn:example.org',
        senderId: '@example:example.org',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
        room: room,
      );

  static Event emptyTextEvent(Room room) => Event(
        content: {
          'body': '',
          'msgtype': 'm.text',
        },
        type: 'm.room.message',
        eventId: '\$143273582443PhrSn:example.org',
        senderId: '@example:example.org',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
        room: room,
      );
}
