import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/join_invitation_error_extension.dart';

MatrixException _matrixException(String errcode, String error) =>
    MatrixException.fromJson({'errcode': errcode, 'error': error});

void main() {
  final l10n = lookupL10n(const Locale('en'));

  test('explains that the room cannot be joined once everyone in it left', () {
    final exception = _matrixException(
      'M_UNKNOWN',
      "Can't join remote room because no servers that are in the room have "
          'been provided.',
    );

    expect(
      exception.toJoinInvitationError(l10n).toString(),
      l10n.cannotJoinRoomEveryoneLeft,
    );
  });

  test('also recognises the older "No known servers" answer', () {
    final exception = _matrixException('M_UNKNOWN', 'No known servers');

    expect(
      exception.toJoinInvitationError(l10n).toString(),
      l10n.cannotJoinRoomEveryoneLeft,
    );
  });

  test('keeps the original exception for an unrelated M_UNKNOWN', () {
    final exception = _matrixException('M_UNKNOWN', 'Internal server error');

    expect(exception.toJoinInvitationError(l10n), same(exception));
  });

  test('keeps the original exception for another errcode', () {
    final exception = _matrixException('M_FORBIDDEN', 'You are banned');

    expect(exception.toJoinInvitationError(l10n), same(exception));
  });
}
