import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';
import 'package:twake_chat/domain/model/chat/message_report_reason.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/report/report_flow.dart';
import 'package:twake_chat/pages/report/report_flow_dialogs.dart';

class _ScriptedDialogs implements ReportFlowDialogs {
  _ScriptedDialogs({
    required List<MessageReportReason?> reasons,
    List<ReportCommentAnswer> comments = const [],
    required List<bool> confirms,
  }) : _reasons = List.of(reasons),
       _comments = List.of(comments),
       _confirms = List.of(confirms);

  final List<MessageReportReason?> _reasons;
  final List<ReportCommentAnswer> _comments;
  final List<bool> _confirms;

  final List<String> confirmedReasons = [];
  final List<String> events = [];

  @override
  Future<MessageReportReason?> pickReason({
    required String title,
    required String description,
  }) async {
    events.add('pick');
    return _reasons.removeAt(0);
  }

  @override
  Future<ReportCommentAnswer> askComment() async {
    events.add('comment');
    return _comments.removeAt(0);
  }

  @override
  Future<bool> confirm(String reason) async {
    events.add('confirm');
    confirmedReasons.add(reason);
    return _confirms.removeAt(0);
  }

  @override
  Future<Object?> runWithLoading(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on Exception catch (exception) {
      return exception;
    }
  }

  @override
  void showReported() => events.add('reported');

  @override
  void showFailed(Object error) => events.add('failed');
}

class _RecordingSubmit {
  _RecordingSubmit({this.failures = 0, this.error});

  int failures;
  final Exception? error;
  final List<String> reasons = [];

  Future<void> call(String reason) async {
    reasons.add(reason);
    if (failures > 0) {
      failures--;
      throw error ?? Exception('server error');
    }
  }
}

Future<void> _run(
  ReportFlowDialogs dialogs,
  Future<void> Function(String) submit,
) => ReportFlow(
  dialogs: dialogs,
  l10n: lookupL10n(const Locale('en')),
).run(title: 'Report', description: 'Why?', submit: submit);

Future<({_ScriptedDialogs dialogs, _RecordingSubmit submit})> _report({
  required List<MessageReportReason?> reasons,
  List<ReportCommentAnswer> comments = const [],
  List<bool> confirms = const [],
  _RecordingSubmit? submit,
}) async {
  final dialogs = _ScriptedDialogs(
    reasons: reasons,
    comments: comments,
    confirms: confirms,
  );
  final recording = submit ?? _RecordingSubmit();
  await _run(dialogs, recording.call);
  return (dialogs: dialogs, submit: recording);
}

void main() {
  test('run_whenThePickerIsDismissed_sendsNothing', () async {
    final (:dialogs, :submit) = await _report(reasons: [null]);

    expect(submit.reasons, isEmpty);
    expect(dialogs.events, ['pick']);
  });

  test('run_whenTheConfirmIsCancelled_sendsNothing', () async {
    final (:dialogs, :submit) = await _report(
      reasons: [MessageReportReason.spam],
      confirms: [false],
    );

    expect(submit.reasons, isEmpty);
    expect(dialogs.events, ['pick', 'confirm']);
  });

  test('run_whenAReasonIsConfirmed_sendsItThenShowsReported', () async {
    final (:dialogs, :submit) = await _report(
      reasons: [MessageReportReason.spam],
      confirms: [true],
    );

    expect(submit.reasons, ['Spam']);
    expect(dialogs.events, ['pick', 'confirm', 'reported']);
  });

  test('run_whenOtherIsChosen_sendsTheReasonWithTheComment', () async {
    final (:dialogs, :submit) = await _report(
      reasons: [MessageReportReason.other],
      comments: [const ReportCommentSubmitted('rude')],
      confirms: [true],
    );

    expect(submit.reasons, ['Other: rude']);
  });

  test('run_whenTheCommentGoesBack_showsThePickerAgain', () async {
    final (:dialogs, :submit) = await _report(
      reasons: [MessageReportReason.other, MessageReportReason.violence],
      comments: [const ReportCommentBack()],
      confirms: [true],
    );

    expect(dialogs.events, ['pick', 'comment', 'pick', 'confirm', 'reported']);
    expect(submit.reasons, ['Violence']);
  });

  test('run_whenTheCommentIsDismissed_sendsNothing', () async {
    final (:dialogs, :submit) = await _report(
      reasons: [MessageReportReason.other],
      comments: [const ReportCommentDismissed()],
    );

    expect(submit.reasons, isEmpty);
  });

  test('run_whenTheServerFails_keepsTheDraftForTheRetry', () async {
    final (:dialogs, :submit) = await _report(
      reasons: [MessageReportReason.other],
      comments: [const ReportCommentSubmitted('rude')],
      confirms: [true, true],
      submit: _RecordingSubmit(failures: 1),
    );

    expect(dialogs.events, [
      'pick',
      'comment',
      'confirm',
      'failed',
      'confirm',
      'reported',
    ]);
    expect(dialogs.confirmedReasons, ['Other: rude', 'Other: rude']);
    expect(submit.reasons, ['Other: rude', 'Other: rude']);
  });

  test('run_whenTheServerFailsAndTheRetryIsCancelled_showsNoSuccess', () async {
    final (:dialogs, submit: _) = await _report(
      reasons: [MessageReportReason.spam],
      confirms: [true, false],
      submit: _RecordingSubmit(failures: 1),
    );

    expect(dialogs.events, ['pick', 'confirm', 'failed', 'confirm']);
  });

  test('run_whenTheServerDoesNotSupportTheReport_stopsWithoutRetry', () async {
    final (:dialogs, :submit) = await _report(
      reasons: [MessageReportReason.spam],
      confirms: [true, true],
      submit: _RecordingSubmit(
        failures: 1,
        error: ReportNotSupportedException(cause: Exception('M_UNRECOGNIZED')),
      ),
    );

    expect(dialogs.events, ['pick', 'confirm', 'failed']);
    expect(submit.reasons, ['Spam']);
  });

  test('run_whileTheServerHasNotAnswered_showsNoSuccess', () async {
    final dialogs = _ScriptedDialogs(
      reasons: [MessageReportReason.spam],
      confirms: [true],
    );
    final pending = Completer<void>();

    final flow = _run(dialogs, (_) => pending.future);
    await Future<void>.delayed(Duration.zero);

    expect(dialogs.events, ['pick', 'confirm']);
    pending.complete();
    await flow;
    expect(dialogs.events, ['pick', 'confirm', 'reported']);
  });
}
