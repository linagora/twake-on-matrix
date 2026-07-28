import 'package:fluffychat/di/global/get_it_initializer.dart' as di;
import 'package:get_it/get_it.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_it_provider.g.dart';

@Riverpod(keepAlive: true)
GetIt getIt(Ref ref) => di.getIt;
