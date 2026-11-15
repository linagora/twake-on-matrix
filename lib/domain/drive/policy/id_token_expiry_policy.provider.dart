import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/drive/policy/id_token_expiry_policy.dart';

part 'id_token_expiry_policy.provider.g.dart';

@Riverpod(keepAlive: true)
IdTokenExpiryPolicy idTokenExpiryPolicy(Ref ref) =>
    const IdTokenExpiryPolicy(skew: Duration(seconds: 60));
