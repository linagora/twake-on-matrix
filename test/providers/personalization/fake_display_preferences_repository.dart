import 'dart:async';

import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';

/// The storage of the display choices and of the seen steps, in memory. What
/// is saved is what the next load reads, as on a device.
class FakeDisplayPreferencesRepository implements DisplayPreferencesRepository {
  FakeDisplayPreferencesRepository({
    this.stored = const DisplayPreferencesState(),
    Set<String> seen = const {},
    this.failLoad = false,
    this.failSave = false,
  }) : seen = {...seen};

  DisplayPreferencesState stored;
  Set<String> seen;

  /// Every load and save throws, as a storage that cannot be read or written.
  bool failLoad;
  bool failSave;

  /// While set and not completed, the storage has not answered yet.
  Completer<void>? gate;

  /// Every write, in order: the choices saved, the seen steps saved.
  final List<DisplayPreferencesState> saved = [];
  final List<Set<String>> savedSeen = [];

  int get writes => saved.length + savedSeen.length;

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

  @override
  Future<Set<String>> loadSeenSteps() async {
    await _wait();
    return {...seen};
  }

  @override
  Future<void> saveSeenSteps(Set<String> steps) async {
    if (failSave) throw Exception('disk full');
    savedSeen.add({...steps});
    seen = {...steps};
  }
}
