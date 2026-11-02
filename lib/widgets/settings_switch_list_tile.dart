import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/utils/famedlysdk_store.provider.dart';

class SettingsSwitchListTile extends ConsumerStatefulWidget {
  final bool defaultValue;
  final String storeKey;
  final String title;
  final Function(bool)? onChanged;

  const SettingsSwitchListTile.adaptive({
    super.key,
    this.defaultValue = false,
    required this.storeKey,
    required this.title,
    this.onChanged,
  });

  @override
  SettingsSwitchListTileState createState() => SettingsSwitchListTileState();
}

class SettingsSwitchListTileState
    extends ConsumerState<SettingsSwitchListTile> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    return FutureBuilder<bool>(
      future: store.getItemBool(widget.storeKey, widget.defaultValue),
      builder: (context, snapshot) => SwitchListTile.adaptive(
        value: snapshot.data ?? widget.defaultValue,
        title: Text(widget.title),
        onChanged: (bool newValue) async {
          widget.onChanged?.call(newValue);
          await store.setItemBool(widget.storeKey, newValue);
          if (!mounted) return;
          setState(() {});
        },
      ),
    );
  }
}
