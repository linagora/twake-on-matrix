import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/sources/pkce_generator.dart';

part 'pkce_generator.provider.g.dart';

@Riverpod(keepAlive: true)
PkceGenerator pkceGenerator(Ref ref) => PkceGenerator(Random.secure());
