import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/utils/famedlysdk_store.provider.dart';

part 'display_preferences_repository.provider.g.dart';

/// Kept alive: the choices are read once per run of the app.
@Riverpod(keepAlive: true)
DisplayPreferencesRepository displayPreferencesRepository(Ref ref) =>
    DisplayPreferencesRepository(ref.watch(storeProvider));
