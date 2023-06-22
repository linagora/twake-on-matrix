import 'dart:async';

import 'package:matrix/matrix.dart';

class MatrixProfilesService {
  final Map<Client, Profile> _profileCache = {};

  MatrixProfilesService();

  void init(List<Client> clients) async {
    for (final client in clients) {
      _profileCache[client] = await client.getProfileFromUserId(client.userID!, cache: false, getFromRooms: false);
    }
  }

  Future<Profile> getProfile(Client client) async {
    if (_profileCache.containsKey(client)) {
      return _profileCache[client]!;
    }
    final profile = await client.getProfileFromUserId(client.userID!, cache: false, getFromRooms: false);
    _profileCache[client] = profile;
    return profile;
  }

  void updateProfile(Client client) async {
    final profile = await client.getProfileFromUserId(client.userID!, cache: false, getFromRooms: false);
    _profileCache[client] = profile;
  }

  Client _getClientByName(String clientName) {
    return _profileCache.keys.firstWhere((element) => element.clientName == clientName);
  }

  void presenceEventHandler(String clientName, CachedPresence event) async {
    Logs().v('MatrixProfilesService::presenceEventHandler():event: ${event.toString()}');
    final client = _getClientByName(clientName);
    if (_profileCache[client]?.userId == event.userid) {
      _profileCache[client] =
          await client.getProfileFromUserId(event.userid, cache: false, getFromRooms: false);
    }
  }

  void roomStateHandler(Event event) {
    Logs().v('MatrixProfilesService::roomStateHandler():event: ${event.toString()}');
  }

  void clearProfileCache() {
    _profileCache.clear();
  }
}
