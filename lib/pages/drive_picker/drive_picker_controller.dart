import 'package:twake_chat/domain/drive/usecases/create_drive_intent_usecase.provider.dart';
import 'package:twake_chat/domain/drive/policy/drive_links_message_policy.provider.dart';
import 'package:twake_chat/domain/drive/policy/drive_pick_plan_policy.provider.dart';
import 'package:twake_chat/domain/drive/usecases/download_drive_files_usecase.provider.dart';
import 'package:twake_chat/pages/drive_picker/providers/drive_picker_platform.provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/domain/drive/entities/drive_picker_options.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_pick_result.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_picker_preparation.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_picker_state.dart';
import 'package:twake_chat/presentation/extensions/drive/drive_document_extension.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/drive_session_provider.dart';
import 'package:twake_drive_picker/core.dart';

part 'drive_picker_controller.g.dart';

/// Opens Drive for one pick and turns what comes back into something the chat
/// can send. Kept alive: the pick outlives any widget that asked for it, and
/// one pick at a time holds across rooms.
@Riverpod(keepAlive: true)
class DrivePickerController extends _$DrivePickerController {
  /// The upload limit read for the pick in progress, for its downloads.
  int? _maxAttachmentBytes;
  int _generation = 0;
  String? _pickUserId;

  @override
  DrivePickerState build() {
    ref.watch(activeUserIdProvider);
    _generation++;
    _maxAttachmentBytes = null;
    _pickUserId = null;
    return const DrivePickerState.idle();
  }

  /// Signs the user in when needed and returns what the sheet needs. Busy when
  /// a pick is already going on. The caller calls [release] when the pick is
  /// over, whatever the outcome.
  ///
  /// [maxAttachmentBytes] gives the homeserver upload limit, or null when it
  /// is not known; it is asked only when the attach button is offered, and it
  /// must not throw.
  Future<DrivePickerPreparation> prepare(
    DrivePickerOptions options, {
    required Future<int?> Function() maxAttachmentBytes,
  }) async {
    if (state is! DrivePickerIdle) return const DrivePickerBusy();
    final generation = ++_generation;
    final userId = ref.read(activeUserIdProvider);
    _pickUserId = userId;
    _move(DrivePickerState.signingIn(generation));
    var prepared = false;
    try {
      final session = await ref.read(driveSessionProvider.notifier).obtain();
      final limit = options.attachLabel == null
          ? null
          : await maxAttachmentBytes();
      if (!isCurrentPick(generation)) {
        return const DrivePickerCancelled();
      }
      _maxAttachmentBytes = limit;
      final withLimit = options.copyWith(maxAttachmentBytes: limit);
      _move(DrivePickerState.open(generation));
      prepared = true;
      return DrivePickerReady(
        DrivePickerRequest(
          intentLoader: () => _loadIntent(session, withLimit, generation),
          platform: ref.read(drivePickerPlatformProvider),
          filePickerConfig: WorkplaceFilePickerConfigRequest(
            sharingLink: WorkplaceActionConfigRequest(label: options.linkLabel),
            downloadLink: withLimit.attachLabel == null
                ? null
                : WorkplaceActionConfigRequest(
                    label: withLimit.attachLabel,
                    maxFileSize: withLimit.maxAttachmentBytes,
                    allowFolder: false,
                  ),
            theme: WorkplaceThemeConfigRequest.fromEntity(
              options.darkTheme ? WorkplaceTheme.dark : WorkplaceTheme.light,
            ),
          ),
        ),
        ticket: generation,
      );
    } on DriveException catch (error) {
      if (!isCurrentPick(generation)) {
        return const DrivePickerCancelled();
      }
      return _preparationOf(error);
    } finally {
      // Any other exit (a cancel, a drop, an unexpected error that reaches the
      // caller) frees the picker too, or it would stay busy until restart.
      if (!prepared) release(generation);
    }
  }

  /// The pick is over (or never started): another one may start.
  void release(int ticket) {
    if (!isCurrentPick(ticket)) return;
    _generation++;
    _maxAttachmentBytes = null;
    _pickUserId = null;
    _move(const DrivePickerState.idle());
  }

  /// Whether [ticket] still owns the picker for the same Matrix account.
  bool isCurrentPick(int ticket) =>
      ref.mounted &&
      _ticketOf(state) == ticket &&
      _pickUserId == ref.read(activeUserIdProvider);

  /// The ticket the picker was last given, or null when it is idle.
  int? _ticketOf(DrivePickerState current) => switch (current) {
    DrivePickerIdle() => null,
    DrivePickerSigningIn(:final ticket) => ticket,
    DrivePickerOpen(:final ticket) => ticket,
  };

  /// Saves [files] to temporary files, one outcome per file, each handed to
  /// [onOutcome] as soon as it is saved. A file over the homeserver upload limit
  /// read by [prepare] is refused.
  ///
  /// The files are the caller's from then on: an account switch does not
  /// delete them, and the picker is free again at once, so the next pick can
  /// start while they are still on their way.
  Future<List<DriveDownloadOutcome>> download(
    List<DrivePickedFile> files, {
    required int ticket,
    required void Function(int index, DriveDownloadOutcome outcome) onOutcome,
  }) {
    _requireCurrentPick(ticket);
    if (state is! DrivePickerOpen) {
      throw StateError('Drive picker is not open');
    }
    final maxBytes = _maxAttachmentBytes;
    release(ticket);
    return ref
        .read(downloadDriveFilesUseCaseProvider)
        .execute(files, maxBytes: maxBytes, onOutcome: onOutcome);
  }

  /// A new try for one file whose download failed, for the retry of its
  /// upload. No picker is open by then, so it needs no pick. It does not
  /// throw: the outcome says why a file did not come.
  Future<DriveDownloadOutcome> downloadAgain(
    DrivePickedFile file, {
    required int? maxBytes,
  }) async {
    final outcomes = await ref.read(downloadDriveFilesUseCaseProvider).execute([
      file,
    ], maxBytes: maxBytes);
    return outcomes.single;
  }

  /// What to do with what Drive gave back.
  DrivePickResult resultOf(DrivePickOutcome outcome, {required int ticket}) {
    if (!isCurrentPick(ticket) || state is! DrivePickerOpen) {
      return const DrivePickNothing();
    }
    return switch (outcome) {
      DrivePickOutcomePicked(:final documents) => _planOf(documents),
      DrivePickOutcomeCancelled() => const DrivePickNothing(),
      // A renewal the user cancelled, or an account switched meanwhile, is not
      // a failure of Drive.
      DrivePickOutcomeFailed(
        error: DriveSignInCancelled() || DriveSessionSuperseded(),
      ) =>
        const DrivePickNothing(),
      DrivePickOutcomeFailed(:final error) => DrivePickFailed(
        _failureOf(error),
      ),
    };
  }

  DrivePickFailure _failureOf(Object error) => switch (error) {
    DriveIntentTimeoutException() => DrivePickFailure.pickerTimedOut,
    DriveIntentPageLoadException() => DrivePickFailure.pickerPageFailed,
    DriveIntentErrorException() => DrivePickFailure.pickerReportedError,
    DriveIntentNoValidDocumentException() =>
      DrivePickFailure.pickerNoValidDocument,
    DriveTimedOut() ||
    DriveOffline() ||
    DriveRateLimited() => DrivePickFailure.intentUnreachable,
    DriveException() => DrivePickFailure.intentFailed,
    _ => DrivePickFailure.pickerFailed,
  };

  DrivePickResult _planOf(List<DriveDocument> documents) {
    final plan = ref
        .read(drivePickPlanPolicyProvider)
        .plan(documents.map((d) => d.toPickedFile()).toList());
    if (plan.links.isNotEmpty) {
      final policy = ref.read(driveLinksMessagePolicyProvider);
      final text = policy.format(plan.links);
      return text.isEmpty
          ? const DrivePickFailed(DrivePickFailure.noLinkToSend)
          : DrivePickLinks(policy.split(text));
    }
    if (plan.downloads.isNotEmpty) {
      return DrivePickAttach(plan.downloads, plan.skippedShortcuts);
    }
    return plan.skippedShortcuts > 0
        ? const DrivePickShortcutsOnly()
        : const DrivePickFailed(DrivePickFailure.nothingToSend);
  }

  Future<WorkplaceIntent> _loadIntent(
    DriveSession session,
    DrivePickerOptions options,
    int generation,
  ) async {
    _requireCurrentPick(generation);
    final intent = await ref
        .read(createDriveIntentUseCaseProvider)
        .execute(
          session: session,
          renewSession: () async {
            _requireCurrentPick(generation);
            final renewed = await ref
                .read(driveSessionProvider.notifier)
                .renew();
            _requireCurrentPick(generation);
            return renewed;
          },
          options: options,
        );
    _requireCurrentPick(generation);
    return WorkplaceIntent(
      intentId: intent.intentId,
      intentUrl: intent.intentUrl,
      client: intent.client,
    );
  }

  void _requireCurrentPick(int ticket) {
    if (!isCurrentPick(ticket)) {
      throw const DriveSessionSuperseded();
    }
  }

  DrivePickerPreparation _preparationOf(DriveException error) =>
      switch (error) {
        DriveSignInCancelled() ||
        DriveSessionSuperseded() => const DrivePickerCancelled(),
        DriveSignInFailed() || DriveWorkplaceUnknown() =>
          const DrivePickerUnavailable(DrivePickerProblem.signInFailed),
        DriveChatAppMissing() => const DrivePickerUnavailable(
          DrivePickerProblem.chatAppMissing,
        ),
        DriveNotConfigured() ||
        DriveExchangeRejected() ||
        DriveIntentFailed() ||
        DriveRateLimited() ||
        DriveTimedOut() ||
        DriveOffline() => const DrivePickerUnavailable(
          DrivePickerProblem.couldNotOpen,
        ),
      };

  void _move(DrivePickerState next) {
    // Switches on the state left, so a new state does not compile until its
    // moves are written.
    final allowed = switch (state) {
      DrivePickerIdle() => next is DrivePickerSigningIn,
      DrivePickerSigningIn() =>
        next is DrivePickerIdle || next is DrivePickerOpen,
      DrivePickerOpen() => next is DrivePickerIdle,
    };
    if (!allowed) {
      throw StateError('Invalid Drive picker state transition');
    }
    state = next;
  }
}
