import 'dart:async';

import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';

/// The storage of the display choices, in memory. What is saved is what the
/// next load reads, as on a device.
class FakeDisplayPreferencesRepository implements DisplayPreferencesRepository {
  FakeDisplayPreferencesRepository({
    this.stored = const DisplayPreferencesState(),
    this.failLoad = false,
    this.failSave = false,
  });

  DisplayPreferencesState stored;

  /// Every load and save throws, as a storage that cannot be read or written.
  bool failLoad;
  bool failSave;

  /// While set and not completed, the storage has not answered yet.
  Completer<void>? gate;

  /// Every write, in order: the choices saved.
  final List<DisplayPreferencesState> saved = [];

  int get writes => saved.length;

  /// Holds every load until [answer].
  void holdLoads() => gate = Completer<void>();

  void answer() => gate?.complete();

  Future<void> _wait() async {
    await gate?.future;
    if (failLoad) throw Exception('storage cannot be read');
  }

  @override
  Future<DisplayPreferencesState> load() async {
    await _wait();
    return stored;
  }

  @override
  Future<void> save(DisplayPreferencesState preferences) async {
    if (failSave) throw Exception('disk full');
    saved.add(preferences);
    stored = preferences;
  }
}
