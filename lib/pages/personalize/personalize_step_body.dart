part of 'personalize_drawings.dart';

/// What the start flow shows to answer [step]: a large drawing of the screen
/// the step changes, with every choice made so far, then one segment per
/// choice under it. A segment applies its choice at once, and the drawing
/// follows. The segment of a choice is keyed `option-<step id>-<choice>`.
class PersonalizeStepBody extends ConsumerWidget {
  const PersonalizeStepBody({super.key, required this.step});

  final PersonalizeStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(displayPreferencesProvider);
    final l10n = L10n.of(context)!;
    final choices = PersonalizeChoices(
      l10n: l10n,
      preferences: preferences,
      controller: ref.read(displayPreferencesControllerProvider.notifier),
    ).of(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _ScreenFrame(
          child: switch (step) {
            PersonalizeStep.density ||
            PersonalizeStep.order => _ListScreen(preferences: preferences),
            _ => _ConversationScreen(preferences: preferences),
          },
        ),
        _Segments(step: step, choices: choices),
        Text(
          l10n.personalizeCompareHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// A phone screen, framed.
class _ScreenFrame extends StatelessWidget {
  const _ScreenFrame({required this.child});

  final Widget child;

  static const double height = 300;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(color: scheme.outlineVariant, width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Text(
        title,
        textScaler: TextScaler.noScaling,
        style: LinagoraTextStyle.material().titleSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

/// The chat list, in the density and the order chosen so far.
class _ListScreen extends StatelessWidget {
  const _ListScreen({required this.preferences});

  final DisplayPreferencesState preferences;

  /// The rooms drawn under each section, as (name, unread).
  static const _samples = {
    RoomSectionKind.unread: [('Alice', true), ('Apollo', true)],
    RoomSectionKind.directs: [('Bruno', false), ('Chloé', false)],
    RoomSectionKind.groups: [('Orion', false), ('Vega', false)],
  };

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final compact = preferences.density == ChatListDensity.compact;
    _NamedRoom room(String name, {bool unread = false}) =>
        _NamedRoom(name: name, unread: unread, compact: compact);
    final rows = preferences.roomOrder == RoomOrder.sections
        ? [
            for (final kind in _previewSections) ...[
              _MiniTitle(_sectionTitle(l10n, kind), scheme: scheme),
              for (final (name, unread) in _samples[kind]!)
                room(name, unread: unread),
            ],
          ]
        : [
            room('Alice', unread: true),
            room('Apollo', unread: true),
            room('Bruno'),
            room('Orion'),
            room('Chloé'),
            room('Vega'),
            room('Lyra'),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScreenTitle(l10n.chats),
        Expanded(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NamedRoom extends StatelessWidget {
  const _NamedRoom({
    required this.name,
    required this.unread,
    required this.compact,
  });

  final String name;
  final bool unread;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
      child: Row(
        spacing: 10,
        children: [
          RoundAvatar(size: compact ? 24 : 36, text: name.characters.first),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  name,
                  textScaler: TextScaler.noScaling,
                  style: LinagoraTextStyle.material().labelMedium.copyWith(
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
                _Bar(widthFactor: 0.8, color: scheme.outlineVariant),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// A conversation with Alice, in the bubble alignment, the seen style and
/// the message field chosen so far.
class _ConversationScreen extends StatelessWidget {
  const _ConversationScreen({required this.preferences});

  final DisplayPreferencesState preferences;

  @override
  Widget build(BuildContext context) {
    final ownRight = preferences.bubbleAlign == BubbleAlign.ownRight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ScreenTitle('Alice'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: ownRight
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              spacing: 6,
              children: [
                const _MiniBubble(own: false, end: false),
                _MiniBubble(own: true, end: ownRight),
                const _MiniBubble(own: false, end: false),
                _MiniBubble(
                  own: true,
                  end: ownRight,
                  trailing: Icon(
                    Icons.done_all,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SeenReaders(
                  style: preferences.seenStyle,
                  readers: _MiniSeen._readers,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _MiniComposer(style: preferences.composerStyle),
          ),
        ),
      ],
    );
  }
}

/// One segment per choice, the current one highlighted.
class _Segments extends StatelessWidget {
  const _Segments({required this.step, required this.choices});

  final PersonalizeStep step;
  final List<PersonalizeChoice> choices;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      // Every segment as tall as the tallest label.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            for (final choice in choices)
              Expanded(
                child: _Segment(
                  key: PersonalizeChoices.keyOf(step, choice.name),
                  choice: choice,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({super.key, required this.choice});

  final PersonalizeChoice choice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(8));
    return Semantics(
      container: true,
      button: true,
      selected: choice.selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: choice.selected ? scheme.surface : Colors.transparent,
        elevation: choice.selected ? 1 : 0,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: choice.onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Center(
              child: Text(
                choice.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: choice.selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
