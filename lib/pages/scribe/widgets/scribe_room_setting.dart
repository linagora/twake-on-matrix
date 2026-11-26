import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/scribe/providers/scribe_room_provider.dart';
import 'package:twake_chat/pages/scribe/scribe_failure_message.dart';
import 'package:twake_chat/pages/scribe/scribe_setting_controller.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

class ScribeRoomSetting extends ConsumerWidget {
  const ScribeRoomSetting({super.key, required this.roomId});

  final String roomId;

  static const _failureMessage = ScribeFailureMessage();
  static const EdgeInsets _padding = EdgeInsets.all(LinagoraSpacing.base * 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfigured = ref.watch(
      driveConfigProvider.select((config) => config.isEnabled),
    );
    if (!isConfigured) return const SizedBox.shrink();
    final room = ref.watch(scribeRoomProvider(roomId)).value;
    if (room == null || !room.hasScribeSetting) {
      return const SizedBox.shrink();
    }
    final wanted = ref.watch(scribeSettingControllerProvider(roomId));
    final l10n = L10n.of(context)!;
    final isOn = wanted?.enabled ?? room.scribeEnabled;
    return LinagoraSettingItem.selectable(
      title: l10n.scribeSettingTitle,
      subtitle: isOn ? l10n.scribeSettingOn : l10n.scribeSettingOff,
      subtitleMaxLines: null,
      padding: _padding,
      value: isOn,
      enabled: room.canChangeScribe && wanted?.saving != true,
      onChanged: (enabled) => _save(context, ref, room, enabled: enabled),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    ScribeRoom room, {
    required bool enabled,
  }) async {
    try {
      await ref
          .read(scribeSettingControllerProvider(roomId).notifier)
          .save(room, enabled: enabled);
    } on Exception catch (e, s) {
      if (e is! ScribeException && e is! DriveException) {
        Logs().e('ScribeRoomSetting::_save', e, s);
      }
      if (!context.mounted) return;
      final message = _failureMessage.ofSetting(L10n.of(context)!, e);
      if (message != null) TwakeSnackBar.show(context, message);
    }
  }
}
