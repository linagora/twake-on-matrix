import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/scribe/providers/scribe_room_provider.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_room_source.provider.dart';
import 'package:twake_chat/pages/scribe/scribe_failure_message.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

/// Whether the Scribe works in an encrypted group, and the owner's switch
/// (Chat web's room info). Hidden elsewhere. The switch shows the wanted value
/// until the sync brings the room's state back.
class ScribeRoomSetting extends ConsumerStatefulWidget {
  const ScribeRoomSetting({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ScribeRoomSetting> createState() => _ScribeRoomSettingState();
}

class _ScribeRoomSettingState extends ConsumerState<ScribeRoomSetting> {
  static const _failureMessage = ScribeFailureMessage();
  static const EdgeInsets _padding = EdgeInsets.all(LinagoraSpacing.base * 2);

  /// The value being saved; null when the switch shows the room's state.
  bool? _wanted;

  @override
  Widget build(BuildContext context) {
    final isConfigured = ref.watch(
      driveConfigProvider.select((config) => config.isEnabled),
    );
    // Without a workplace the room is not even read.
    if (!isConfigured) return const SizedBox.shrink();
    ref.listen(scribeRoomProvider(widget.roomId).select((room) => room.value), (
      _,
      room,
    ) {
      if (room != null && room.scribeEnabled == _wanted) {
        setState(() => _wanted = null);
      }
    });
    final room = ref.watch(scribeRoomProvider(widget.roomId)).value;
    if (room == null || !room.hasScribeSetting) {
      return const SizedBox.shrink();
    }
    final l10n = L10n.of(context)!;
    final isOn = _wanted ?? room.scribeEnabled;
    return LinagoraSettingItem.selectable(
      title: l10n.scribeSettingTitle,
      subtitle: isOn ? l10n.scribeSettingOn : l10n.scribeSettingOff,
      subtitleMaxLines: null,
      padding: _padding,
      value: isOn,
      enabled: room.canChangeScribe && _wanted == null,
      onChanged: (enabled) => _save(room, enabled: enabled),
    );
  }

  Future<void> _save(ScribeRoom room, {required bool enabled}) async {
    if (!room.canChangeScribe) return;
    setState(() => _wanted = enabled);
    try {
      await ref
          .read(scribeRoomSourceProvider)
          .setScribeEnabled(widget.roomId, enabled: enabled);
    } on Exception catch (e, s) {
      // The source logs the failure it maps; an unmapped one is a bug.
      if (e is! ScribeException && e is! DriveException) {
        Logs().e('ScribeRoomSetting::_save', e, s);
      }
      if (!mounted) return;
      setState(() => _wanted = null);
      final message = _failureMessage.of(L10n.of(context)!, e);
      if (message != null) TwakeSnackBar.show(context, message);
    }
  }
}
