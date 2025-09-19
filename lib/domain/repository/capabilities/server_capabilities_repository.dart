import 'package:matrix/matrix.dart';

abstract class ServerCapabilitiesRepository {
  Future<Capabilities> getCapabilities();
}
