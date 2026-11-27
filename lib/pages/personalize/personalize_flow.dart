import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/personalize/personalize_question.dart';
import 'package:twake_chat/pages/personalize/personalize_drawings.dart';
import 'package:twake_chat/providers/personalization/personalize_steps_controller.dart';

/// The steps the device has not seen, one per screen. A choice applies at
/// once; the steps are fixed when the flow opens, and every way out (Done,
/// close, system back, More options) remembers them all as seen.
class PersonalizeFlow extends ConsumerStatefulWidget {
  const PersonalizeFlow({super.key, required this.steps});

  final List<PersonalizeStep> steps;

  @override
  ConsumerState<PersonalizeFlow> createState() => _PersonalizeFlowState();
}

class _PersonalizeFlowState extends ConsumerState<PersonalizeFlow> {
  late final List<PersonalizeStep> _steps = List.unmodifiable(widget.steps);
  int _index = 0;
  bool _seen = false;

  void _markSeen() {
    if (_seen) return;
    _seen = true;
    unawaited(
      ref.read(personalizeStepsControllerProvider.notifier).markSeen(_steps),
    );
  }

  void _close() => Navigator.of(context).maybePop();

  void _moreOptions() {
    final router = GoRouter.of(context);
    _markSeen();
    Navigator.of(context).pop();
    router.push(const PersonalizationRoute().location);
  }

  void _onPopInvoked(bool didPop, Object? _) {
    if (didPop) _markSeen();
  }

  void _back() => setState(() => _index--);

  void _next() => setState(() => _index++);

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) return const SizedBox.shrink();
    final l10n = L10n.of(context)!;
    final step = _steps[_index];
    final isLast = _index == _steps.length - 1;
    return PopScope(
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: const ValueKey('personalize-close'),
            tooltip: l10n.close,
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
          title: Text(l10n.personalization),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Text(
                  l10n.personalizeStepCounter(_index + 1, _steps.length),
                  key: const ValueKey('personalize-step-counter'),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: (_index + 1) / _steps.length),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                personalizeQuestion(l10n, step),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                l10n.personalizeHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              PersonalizeStepBody(key: ValueKey(step), step: step),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    if (_index > 0)
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('personalize-back'),
                          onPressed: _back,
                          child: Text(l10n.back),
                        ),
                      ),
                    Expanded(
                      child: isLast
                          ? FilledButton(
                              key: const ValueKey('personalize-done'),
                              onPressed: _close,
                              child: Text(l10n.done),
                            )
                          : FilledButton(
                              key: const ValueKey('personalize-next'),
                              onPressed: _next,
                              child: Text(l10n.next),
                            ),
                    ),
                  ],
                ),
                TextButton(
                  key: const ValueKey('personalize-more'),
                  onPressed: _moreOptions,
                  child: Text(l10n.personalizeMoreOptions),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
