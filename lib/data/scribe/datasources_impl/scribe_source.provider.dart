import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/sources/workplace_token_exchange.provider.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_source_impl.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';

part 'scribe_source.provider.g.dart';

@Riverpod(keepAlive: true)
ScribeSource scribeSource(Ref ref) =>
    ScribeSourceImpl(exchange: ref.watch(workplaceTokenExchangeProvider));
