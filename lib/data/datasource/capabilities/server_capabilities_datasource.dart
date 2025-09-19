import 'package:matrix/matrix.dart';

abstract class ServerCapabilitiesDatasource {
  Future<Capabilities> getCapabilities();
}
