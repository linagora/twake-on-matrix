import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/sources/drive_dio.provider.dart';
import 'package:twake_chat/data/drive/sources/workplace_token_exchange.dart';

part 'workplace_token_exchange.provider.g.dart';

@Riverpod(keepAlive: true)
WorkplaceTokenExchange workplaceTokenExchange(Ref ref) =>
    WorkplaceTokenExchangeImpl(
      dio: ref.watch(driveDioProvider),
      requireHttps: true,
    );
