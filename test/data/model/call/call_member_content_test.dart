import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/model/call/call_member_content.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

const _room = CallRoom('!room:hs.test');
const _alice = CallDevice(userId: '@alice:localhost', deviceId: 'DEV');

void main() {
  test('toJson_forAJoin_isAnMsc4143SessionMembership', () {
    // Arrange
    const join = CallJoin(
      room: _room,
      serviceUrl: 'http://127.0.0.1:3003',
      isVideo: true,
    );

    // Act
    final json = CallMemberContent.forJoin(_alice, join).toJson();

    // Assert
    expect(json, {
      'application': 'm.call',
      'call_id': '',
      'scope': 'm.room',
      'device_id': 'DEV',
      'membershipID': '@alice:localhost:DEV',
      'expires': 14400000,
      'm.call.intent': 'video',
      'focus_active': {
        'type': 'livekit',
        'focus_selection': 'oldest_membership',
      },
      'foci_preferred': [
        {'type': 'livekit', 'livekit_service_url': 'http://127.0.0.1:3003'},
      ],
    });
  });

  test('toJson_forAnExtension_keepsTheCreatedTsAndGrowsExpires', () {
    // Arrange
    const join = CallJoin(room: _room, serviceUrl: 'http://127.0.0.1:3003');

    // Act
    final json = CallMemberContent.forJoin(_alice, join, (
      count: 2,
      createdTs: 1700000000000,
    )).toJson();

    // Assert
    expect(json['expires'], 28800000);
    expect(json['created_ts'], 1700000000000);
  });

  test('fromJson_ofALeftMembership_hasNoDevice', () {
    // Act
    final content = CallMemberContent.fromJson(const {});

    // Assert
    expect(content.deviceId, isNull);
  });

  test('fromJson_withADeviceThatIsNotAString_hasNoDevice', () {
    // Act
    final content = CallMemberContent.fromJson(const {'device_id': 3});

    // Assert
    expect(content.deviceId, isNull);
  });

  test('fromJson_ofAMembership_readsItsDevice', () {
    // Act
    final content = CallMemberContent.fromJson(const {
      'device_id': 'DEV',
      'expires': 'not read',
    });

    // Assert
    expect(content.deviceId, 'DEV');
  });
}
