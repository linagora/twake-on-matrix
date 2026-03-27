import 'dart:io';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_space/storage_space.dart';

import 'package:fluffychat/di/global/get_it_initializer.dart';

import 'settings_data_and_storage_calculator.dart';
import 'settings_data_and_storage_constants.dart';
import 'settings_data_and_storage_scanner_service.dart';
import 'settings_data_and_storage_view.dart';

class SettingsDataAndStorage extends StatefulWidget {
  const SettingsDataAndStorage({super.key});

  @override
  SettingsDataAndStorageController createState() =>
      SettingsDataAndStorageController();
}

class SettingsDataAndStorageController extends State<SettingsDataAndStorage> {
  final StorageScannerService _scannerService = getIt
      .get<StorageScannerService>();

  double _totalStorageBytes = 0;

  StorageScanResult _scanResult = const StorageScanResult();
  bool _isScanning = true;

  bool get isScanning => _isScanning;
  double get totalCacheBytes => _scanResult.totalBytes.toDouble();

  double get storageUsageRatio =>
      StorageCalculator.usageRatio(totalCacheBytes, _totalStorageBytes);

  String get storageUsagePercent =>
      StorageCalculator.usagePercent(totalCacheBytes, _totalStorageBytes);

  String formattedBytesFor(StorageCategory category) =>
      StorageCalculator.formatBytes(_scanResult.bytesFor(category).toDouble());

  String get formattedTotalCache =>
      StorageCalculator.formatBytes(totalCacheBytes);

  @override
  void initState() {
    super.initState();
    _initDataAndStorage();
  }

  Future<void> _initDataAndStorage() async {
    try {
      _totalStorageBytes = await _getTotalStorageBytes();
      _scanResult = await _getCacheCategories();
    } catch (e, s) {
      Logs().wtf('SettingsDataAndStorage:_initDataAndStorage', e, s);
    } finally {
      _isScanning = false;
    }
    if (mounted) setState(() {});
  }

  Future<double> _getTotalStorageBytes() async {
    try {
      final storageSpace = await getStorageSpace(
        lowOnSpaceThreshold: 0,
        fractionDigits: 0,
      );
      return storageSpace.total.toDouble();
    } catch (e, s) {
      Logs().e('SettingsDataAndStorage::_getTotalStorageBytes', e, s);
      rethrow;
    }
  }

  Future<StorageScanResult> _getCacheCategories() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final Map<StorageCategory, int> result = await _scannerService
          .scanDirectory(tempDir.path);
      return StorageScanResult(result);
    } catch (e, s) {
      Logs().e('SettingsDataAndStorage::_getCacheCategories', e, s);
      rethrow;
    }
  }

  Future<void> onClearCache(BuildContext context) async {
    final l10n = L10n.of(context)!;
    if (_isScanning) {
      TwakeSnackBar.show(context, l10n.cacheIsScanning);
      return;
    }
    final confirmed = await showConfirmAlertDialog(
      context: context,
      title: l10n.clearCacheConfirmTitle,
      message: l10n.clearCacheConfirmMessage,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
    );
    if (confirmed != ConfirmResult.ok) return;

    await _clearCacheDir(context);
    await _rescanCache();
  }

  Future<void> _clearCacheDir(BuildContext context) async {
    final l10n = L10n.of(context)!;
    try {
      final Directory tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await for (final entity in tempDir.list()) {
          await entity.delete(recursive: true);
        }
      }
      if (context.mounted) {
        TwakeSnackBar.show(context, l10n.cacheClearedSuccessfully);
      }
    } catch (e, s) {
      Logs().e('SettingsDataAndStorage:_clearCacheDir', e, s);
    }

    if (!context.mounted) return;
    setState(() {
      _scanResult = const StorageScanResult();
      _isScanning = true;
    });
  }

  Future<void> _rescanCache() async {
    try {
      _scanResult = await _getCacheCategories();
    } catch (e, s) {
      Logs().e('SettingsDataAndStorage:_rescanCache', e, s);
    }
    _isScanning = false;
    if (context.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => SettingsDataAndStorageView(this);
}
