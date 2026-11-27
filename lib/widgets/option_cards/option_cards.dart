import 'package:flutter/material.dart';

/// How the cards share the width: a tall preview side by side, a wide one
/// stacked.
enum OptionCardsLayout { sideBySide, stacked }

/// One choice: its label and what it looks like. [key] goes on its card.
class OptionCardChoice<T> {
  const OptionCardChoice({
    required this.value,
    required this.label,
    required this.preview,
    this.key,
  });

  final T value;
  final String label;
  final Widget preview;
  final Key? key;
}

/// A choice among a few, each shown as a card with its preview. The whole
/// card selects it; a screen reader hears the chosen one as selected.
class OptionCards<T> extends StatelessWidget {
  const OptionCards({
    super.key,
    required this.value,
    required this.choices,
    required this.onChanged,
    this.layout = OptionCardsLayout.stacked,
  });

  final T value;
  final List<OptionCardChoice<T>> choices;
  final ValueChanged<T> onChanged;
  final OptionCardsLayout layout;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final choice in choices)
        _OptionCard(
          key: choice.key,
          label: choice.label,
          preview: choice.preview,
          selected: choice.value == value,
          onTap: () => onChanged(choice.value),
        ),
    ];
    if (layout == OptionCardsLayout.stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _gap,
        children: cards,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Whole pixels: shared fractions would round past the edge.
        final width =
            ((constraints.maxWidth - _gap * (cards.length - 1)) / cards.length)
                .floorToDouble();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.label,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(12);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                // The preview only shows: a tap on it chooses the card.
                IgnorePointer(
                  child: ExcludeSemantics(
                    child: FittedBox(fit: BoxFit.scaleDown, child: preview),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
