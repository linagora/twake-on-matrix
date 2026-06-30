import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/pages/onboarding/onboarding_view_style.dart';
import 'package:fluffychat/pages/onboarding/widgets/onboarding_primary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class OnboardingPayoffStep extends StatelessWidget {
  static const int _maxAvatars = 3;

  final ValueNotifier<bool> syncStartedNotifier;
  final ValueListenable<Either<Failure, Success>> phonebookContactsListenable;
  final VoidCallback onFinish;

  const OnboardingPayoffStep({
    super.key,
    required this.syncStartedNotifier,
    required this.phonebookContactsListenable,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: OnboardingViewStyle.screenPadding,
      child: ValueListenableBuilder<bool>(
        valueListenable: syncStartedNotifier,
        builder: (context, syncStarted, _) {
          if (!syncStarted) {
            return _PayoffContent(
              matched: const [],
              isLoading: false,
              onFinish: onFinish,
            );
          }
          return ValueListenableBuilder<Either<Failure, Success>>(
            valueListenable: phonebookContactsListenable,
            builder: (context, state, __) {
              final matched = _matchedContacts(state);
              final isLoading = _isLoading(state);
              return _PayoffContent(
                matched: matched,
                isLoading: isLoading,
                onFinish: onFinish,
              );
            },
          );
        },
      ),
    );
  }

  bool _isLoading(Either<Failure, Success> state) {
    return state.fold((failure) => false, (success) {
      if (success is GetPhonebookContactsLoading) return true;
      if (success is GetPhonebookContactsSuccess) {
        return success.progress < 100;
      }
      return true;
    });
  }

  List<Contact> _matchedContacts(Either<Failure, Success> state) {
    return state.fold(
      (failure) => const [],
      (success) =>
          success is GetPhonebookContactsSuccess ? success.contacts : const [],
    );
  }
}

class _PayoffContent extends StatelessWidget {
  final List<Contact> matched;
  final bool isLoading;
  final VoidCallback onFinish;

  const _PayoffContent({
    required this.matched,
    required this.isLoading,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    final theme = Theme.of(context);
    final hasMatches = matched.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                CircularProgressIndicator(color: colors.primary),
                const SizedBox(height: OnboardingViewStyle.titleSpacing),
                Text(
                  l10n.onboardingPayoffLoading,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                Text(
                  hasMatches
                      ? l10n.onboardingPayoffTitle(matched.length)
                      : l10n.onboardingPayoffEmptyTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: OnboardingViewStyle.subtitleSpacing),
                Text(
                  hasMatches
                      ? l10n.onboardingPayoffSubtitle
                      : l10n.onboardingPayoffEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (hasMatches) ...[
                  const SizedBox(height: OnboardingViewStyle.titleSpacing),
                  _MatchedAvatars(matched: matched),
                ],
              ],
            ],
          ),
        ),
        OnboardingPrimaryButton(
          label: hasMatches
              ? l10n.onboardingPayoffStartChatting
              : l10n.onboardingPayoffContinue,
          onTap: isLoading ? null : onFinish,
        ),
      ],
    );
  }
}

class _MatchedAvatars extends StatelessWidget {
  final List<Contact> matched;

  const _MatchedAvatars({required this.matched});

  String _initials(Contact contact) {
    final name = contact.displayName?.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    final theme = Theme.of(context);
    final visible = matched.take(OnboardingPayoffStep._maxAvatars).toList();
    final remaining = matched.length - visible.length;
    return Column(
      children: [
        for (final contact in visible)
          Padding(
            padding: const EdgeInsets.only(
              bottom: OnboardingViewStyle.avatarItemSpacing,
            ),
            child: Row(
              children: [
                _InitialsAvatar(initials: _initials(contact)),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    contact.displayName ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (remaining > 0)
          Text(
            L10n.of(context)!.onboardingPayoffMoreContacts(remaining),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    return Container(
      width: OnboardingViewStyle.avatarSize,
      height: OnboardingViewStyle.avatarSize,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: colors.primary),
      ),
    );
  }
}
