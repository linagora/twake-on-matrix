import 'package:flutter_riverpod/flutter_riverpod.dart';

ProviderContainer createAppProviderContainer() =>
    ProviderContainer(retry: (_, _) => null);
