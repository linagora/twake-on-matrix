import 'settings_data_and_storage_constants.dart';

abstract class StorageScannerService {
  Future<Map<StorageCategory, int>> scanDirectory(String dirPath);
}
