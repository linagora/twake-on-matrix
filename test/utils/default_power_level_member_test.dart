import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getDefaultPowerLevelByUsersDefault test', () {
    test('with users_fault from -1', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: -1,
      );
      expect(result, DefaultPowerLevelMember.guest);
    });

    test('with users_fault from 0', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 0,
      );
      expect(result, DefaultPowerLevelMember.guest);
    });

    test('with users_fault from 5', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 5,
      );
      expect(result, DefaultPowerLevelMember.guest);
    });

    test('with users_fault from 8', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 8,
      );
      expect(result, DefaultPowerLevelMember.guest);
    });

    test('with users_fault from 2', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 2,
      );
      expect(result, DefaultPowerLevelMember.guest);
    });

    test('with users_fault from 10', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 10,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 10', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 10,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 12', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 12,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 10', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 15,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 10', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 17,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 10', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 19,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 20', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 20,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 25', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 25,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 30', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 30,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 35', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 35,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 40', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 40,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 45', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 45,
      );
      expect(result, DefaultPowerLevelMember.member);
    });

    test('with users_fault from 50', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 50,
      );
      expect(result, DefaultPowerLevelMember.moderator);
    });

    test('with users_fault from 55', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 55,
      );
      expect(result, DefaultPowerLevelMember.moderator);
    });

    test('with users_fault from 60', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 60,
      );
      expect(result, DefaultPowerLevelMember.moderator);
    });

    test('with users_fault from 65', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 65,
      );
      expect(result, DefaultPowerLevelMember.moderator);
    });

    test('with users_fault from 70', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 70,
      );
      expect(result, DefaultPowerLevelMember.moderator);
    });

    test('with users_fault from 79', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 79,
      );
      expect(result, DefaultPowerLevelMember.moderator);
    });

    test('with users_fault from 80', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 80,
      );
      expect(result, DefaultPowerLevelMember.admin);
    });

    test('with users_fault from 85', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 85,
      );
      expect(result, DefaultPowerLevelMember.admin);
    });

    test('with users_fault from 90', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 90,
      );
      expect(result, DefaultPowerLevelMember.owner);
    });

    test('with users_fault from 99', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 99,
      );
      expect(result, DefaultPowerLevelMember.owner);
    });

    test('with users_fault from 100', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 100,
      );
      expect(result, DefaultPowerLevelMember.owner);
    });

    test('with users_fault from 1000', () {
      final result = DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
        usersDefault: 1000,
      );
      expect(result, DefaultPowerLevelMember.owner);
    });
  });
}
