import 'package:twake_chat/domain/contact/services/contact_sync_session.dart';

/// A second-pass operation that enriches the contacts already stored.
///
/// Unlike [ContactSource] (which is fetched in parallel and merged by
/// `matrixId`), an enricher runs after the base sync because it needs the
/// stored contacts to know what to fetch (e.g. per-user TOM `user_info`).
abstract class ContactEnricher {
  Future<void> enrich({ContactSyncSession? session});
}
