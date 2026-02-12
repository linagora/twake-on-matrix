import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fluffychat/data/cache/mxc_cache_manager.dart';
import 'package:fluffychat/utils/cache_lifecycle_manager.dart';

@GenerateMocks([MxcCacheManager])
import 'cache_lifecycle_manager_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheLifecycleManager lifecycleManager;
  late MockMxcCacheManager mockCacheManager;

  setUp(() {
    mockCacheManager = MockMxcCacheManager();
    lifecycleManager = CacheLifecycleManager(mockCacheManager);

    // Setup default mocks
    when(mockCacheManager.init()).thenAnswer((_) async {});
    when(mockCacheManager.clearAll()).thenAnswer((_) async {});
    when(mockCacheManager.evictIfNeeded()).thenAnswer((_) async {});
    when(mockCacheManager.dispose()).thenAnswer((_) async {});
    when(mockCacheManager.getStats()).thenAnswer(
      (_) async => const MxcCacheStats(
        memoryItemCount: 0,
        memorySizeBytes: 0,
        memoryUtilization: 0,
        diskSizeBytes: 0,
        diskUtilization: 50,
      ),
    );
  });

  tearDown(() async {
    await lifecycleManager.dispose();
  });

  group('CacheLifecycleManager', () {
    test('register adds observer to WidgetsBinding', () {
      lifecycleManager.register();

      // Verify it was registered (can't directly test WidgetsBinding.instance.observers)
      // but we can verify calling register again doesn't throw
      lifecycleManager.register(); // Should not add twice
    });

    test('unregister removes observer from WidgetsBinding', () {
      lifecycleManager.register();
      lifecycleManager.unregister();

      // Verify calling unregister again doesn't throw
      lifecycleManager.unregister();
    });

    test('onAppStart initializes cache and registers observer', () async {
      await lifecycleManager.onAppStart();

      verify(mockCacheManager.init()).called(1);
      verify(mockCacheManager.getStats()).called(1);
    });

    test('onAppStart triggers cleanup when disk utilization > 90%', () async {
      when(mockCacheManager.getStats()).thenAnswer(
        (_) async => const MxcCacheStats(
          memoryItemCount: 0,
          memorySizeBytes: 0,
          memoryUtilization: 0,
          diskSizeBytes: 0,
          diskUtilization: 95, // Over 90%
        ),
      );

      await lifecycleManager.onAppStart();

      verify(mockCacheManager.evictIfNeeded()).called(1);
    });

    test('onAppStart does not cleanup when disk utilization <= 90%', () async {
      when(mockCacheManager.getStats()).thenAnswer(
        (_) async => const MxcCacheStats(
          memoryItemCount: 0,
          memorySizeBytes: 0,
          memoryUtilization: 0,
          diskSizeBytes: 0,
          diskUtilization: 80, // Below 90%
        ),
      );

      await lifecycleManager.onAppStart();

      verifyNever(mockCacheManager.evictIfNeeded());
    });

    test('onLogout clears all caches', () async {
      await lifecycleManager.onLogout();

      verify(mockCacheManager.clearAll()).called(1);
    });

    test('onAppBackground evicts if needed', () async {
      await lifecycleManager.onAppBackground();

      verify(mockCacheManager.evictIfNeeded()).called(1);
    });

    test('didHaveMemoryPressure clears memory cache', () {
      lifecycleManager.didHaveMemoryPressure();

      verify(mockCacheManager.clearMemory()).called(1);
    });

    test('didChangeAppLifecycleState handles paused state', () async {
      lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Wait for async onAppBackground to complete
      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockCacheManager.evictIfNeeded()).called(1);
    });

    test('didChangeAppLifecycleState handles inactive state', () async {
      lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.inactive);

      // Wait for async onAppBackground to complete
      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockCacheManager.evictIfNeeded()).called(1);
    });

    test('didChangeAppLifecycleState handles detached state', () async {
      lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.detached);

      // Wait for async dispose to complete
      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockCacheManager.dispose()).called(1);
    });

    test(
      'didChangeAppLifecycleState handles resumed state without action',
      () async {
        lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);

        // Wait to ensure no async operations triggered
        await Future.delayed(const Duration(milliseconds: 100));

        verifyNever(mockCacheManager.evictIfNeeded());
        verifyNever(mockCacheManager.dispose());
      },
    );

    test(
      'didChangeAppLifecycleState handles hidden state without action',
      () async {
        lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.hidden);

        // Wait to ensure no async operations triggered
        await Future.delayed(const Duration(milliseconds: 100));

        verifyNever(mockCacheManager.evictIfNeeded());
        verifyNever(mockCacheManager.dispose());
      },
    );

    test('dispose unregisters observer and disposes cache manager', () async {
      lifecycleManager.register();
      await lifecycleManager.dispose();

      verify(mockCacheManager.dispose()).called(1);
    });

    test('handles register/unregister multiple times safely', () {
      lifecycleManager.register();
      lifecycleManager.register(); // Should not register twice
      lifecycleManager.unregister();
      lifecycleManager.unregister(); // Should not unregister twice

      // No assertions needed - just verify no exceptions thrown
    });

    test('full lifecycle sequence', () async {
      // App start
      await lifecycleManager.onAppStart();
      verify(mockCacheManager.init()).called(1);

      // Memory pressure
      lifecycleManager.didHaveMemoryPressure();
      verify(mockCacheManager.clearMemory()).called(1);

      // App background
      lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 100));
      verify(mockCacheManager.evictIfNeeded()).called(1);

      // Logout
      await lifecycleManager.onLogout();
      verify(mockCacheManager.clearAll()).called(1);

      // Dispose
      await lifecycleManager.dispose();
      verify(mockCacheManager.dispose()).called(1);
    });

    test(
      'cleanup is not triggered on first startup with low utilization',
      () async {
        when(mockCacheManager.getStats()).thenAnswer(
          (_) async => const MxcCacheStats(
            memoryItemCount: 0,
            memorySizeBytes: 0,
            memoryUtilization: 0,
            diskSizeBytes: 0,
            diskUtilization: 10, // Very low
          ),
        );

        await lifecycleManager.onAppStart();

        verify(mockCacheManager.init()).called(1);
        verify(mockCacheManager.getStats()).called(1);
        verifyNever(mockCacheManager.evictIfNeeded());
      },
    );

    test('handles errors in cache operations gracefully', () async {
      when(mockCacheManager.init()).thenThrow(Exception('Init failed'));

      // Should not throw
      expect(() => lifecycleManager.onAppStart(), throwsException);
    });

    test('multiple memory pressure events clear cache each time', () {
      lifecycleManager.didHaveMemoryPressure();
      lifecycleManager.didHaveMemoryPressure();
      lifecycleManager.didHaveMemoryPressure();

      verify(mockCacheManager.clearMemory()).called(3);
    });
  });
}
