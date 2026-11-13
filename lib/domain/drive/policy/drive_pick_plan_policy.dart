import 'package:twake_chat/domain/drive/entities/drive_pick_plan.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';

/// Decides what a pick means, as the web app does: if Drive gave sharing links
/// the user chose "link", else "attach". Shortcuts are never attached.
class DrivePickPlanPolicy {
  const DrivePickPlanPolicy({required this.requireHttps});

  /// Release builds only download over https.
  final bool requireHttps;

  static const _shortcutMimeType = 'application/internet-shortcut';

  DrivePickPlan plan(List<DrivePickedFile> files) {
    if (files.any((file) => file.shareUri != null)) {
      final links = files.where((file) => file.shareUri != null).toList();
      return DrivePickPlan(links: links);
    }
    final downloads = <DrivePickedFile>[];
    var shortcuts = 0;
    for (final file in files) {
      if (_isShortcut(file)) {
        shortcuts++;
      } else if (_canDownload(file)) {
        downloads.add(file);
      }
    }
    return DrivePickPlan(downloads: downloads, skippedShortcuts: shortcuts);
  }

  /// A Cozy shortcut: a `.url` file whose bytes are a link.
  bool _isShortcut(DrivePickedFile file) =>
      file.mimeType == _shortcutMimeType ||
      file.name.toLowerCase().endsWith('.url');

  bool _canDownload(DrivePickedFile file) {
    final uri = file.downloadUri;
    if (uri == null || !uri.hasAuthority) return false;
    return uri.isScheme('https') || (!requireHttps && uri.isScheme('http'));
  }
}
