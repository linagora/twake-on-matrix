import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/mxc_image.dart';

void main() {
  testWidgets('MxcImage_whenNoActiveClient_keepsThePlaceholder', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activeMatrixClientProvider.overrideWithValue(null)],
        child: MaterialApp(
          home: MxcImage(
            uri: Uri.parse('mxc://localhost/media'),
            width: 40,
            height: 40,
            placeholder: (_) => const SizedBox(key: Key('placeholder')),
          ),
        ),
      ),
    );

    // Act
    await tester.pump();
    await tester.pump();

    // Assert
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('placeholder')), findsOneWidget);
  });
}
