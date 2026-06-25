import 'package:fluffychat/pages/chat_list/get_started_guide/get_started_guide_style.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One actionable step of the "Get started" guide shown on the Chats page.
class GetStartedStep {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;

  /// Deep-link / action triggered by the step button. May be null for a
  /// passive step (e.g. "receive a message") that only waits to be checked off.
  final VoidCallback? onAction;

  const GetStartedStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.onAction,
  });
}

/// Collapsible, carousel-style onboarding guide. One step at a time with a
/// progress bar; the carousel advances to the next unfinished step once the
/// current one is marked done.
///
/// ponytail: completion is driven by a manual "mark done" + the action
/// deep-link. Real event detection (contacts-synced count, pusher
/// message-received, room-joined) is the upgrade path — wire each step's
/// `done` to the matching Matrix signal when product wants it automatic.
class GetStartedGuide extends StatefulWidget {
  final List<GetStartedStep> steps;

  const GetStartedGuide({super.key, required this.steps});

  @override
  State<GetStartedGuide> createState() => _GetStartedGuideState();
}

class _GetStartedGuideState extends State<GetStartedGuide> {
  static const _completedKey = 'get_started_completed';
  static const _collapsedKey = 'get_started_collapsed';
  static const _dismissedKey = 'get_started_dismissed';

  final PageController _pageController = PageController();
  final Set<int> _completed = {};
  bool _collapsed = false;
  bool _dismissed = false;
  bool _loaded = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _completed
        ..clear()
        ..addAll(completed.map(int.tryParse).whereType<int>());
      _collapsed = prefs.getBool(_collapsedKey) ?? false;
      _dismissed = prefs.getBool(_dismissedKey) ?? false;
      _currentPage = _firstUnfinished();
      _loaded = true;
    });
    if (_pageController.hasClients && _currentPage != 0) {
      _pageController.jumpToPage(_currentPage);
    }
  }

  int _firstUnfinished() {
    for (var i = 0; i < widget.steps.length; i++) {
      if (!_completed.contains(i)) return i;
    }
    return widget.steps.length - 1;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _completedKey,
      _completed.map((e) => e.toString()).toList(),
    );
    await prefs.setBool(_collapsedKey, _collapsed);
    await prefs.setBool(_dismissedKey, _dismissed);
  }

  bool get _allDone => _completed.length >= widget.steps.length;

  void _toggleCollapsed() {
    setState(() => _collapsed = !_collapsed);
    _persist();
  }

  void _dismiss() {
    setState(() => _dismissed = true);
    _persist();
  }

  void _markDone(int index) {
    setState(() => _completed.add(index));
    _persist();
    // Advance to the next unfinished step.
    final next = _firstUnfinished();
    if (!_allDone && next != index) {
      _pageController.animateToPage(
        next,
        duration: GetStartedGuideStyle.animationDuration,
        curve: GetStartedGuideStyle.animationCurve,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed || widget.steps.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = LinagoraSysColors.material();
    final theme = Theme.of(context);

    return Container(
      margin: GetStartedGuideStyle.margin,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(GetStartedGuideStyle.radius),
        border: Border.all(color: colors.outline.withOpacity(0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, colors, theme),
          AnimatedSize(
            duration: GetStartedGuideStyle.animationDuration,
            curve: GetStartedGuideStyle.animationCurve,
            alignment: Alignment.topCenter,
            child: _collapsed
                ? const SizedBox(width: double.infinity)
                : _buildBody(context, colors, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic colors, ThemeData theme) {
    final l10n = L10n.of(context)!;
    return InkWell(
      onTap: _toggleCollapsed,
      child: Padding(
        padding: GetStartedGuideStyle.headerPadding,
        child: Row(
          children: [
            Icon(Icons.rocket_launch_outlined, color: colors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.getStartedTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.getStartedProgress(
                      _completed.length,
                      widget.steps.length,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_allDone)
              IconButton(
                tooltip: l10n.close,
                icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                onPressed: _dismiss,
              ),
            AnimatedRotation(
              turns: _collapsed ? 0.5 : 0,
              duration: GetStartedGuideStyle.animationDuration,
              child: Icon(Icons.expand_less, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, dynamic colors, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress bar above the current step.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              GetStartedGuideStyle.progressBarRadius,
            ),
            child: LinearProgressIndicator(
              value: widget.steps.isEmpty
                  ? 0
                  : _completed.length / widget.steps.length,
              minHeight: GetStartedGuideStyle.progressBarHeight,
              backgroundColor: colors.outline.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
        ),
        SizedBox(
          height: GetStartedGuideStyle.pageViewHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.steps.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) =>
                _buildStep(context, colors, theme, index),
          ),
        ),
        _buildDots(colors),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,
    dynamic colors,
    ThemeData theme,
    int index,
  ) {
    final l10n = L10n.of(context)!;
    final step = widget.steps[index];
    final done = _completed.contains(index);
    return Padding(
      padding: GetStartedGuideStyle.stepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: GetStartedGuideStyle.stepIconBoxSize,
                height: GetStartedGuideStyle.stepIconBoxSize,
                decoration: BoxDecoration(
                  color: done
                      ? colors.primary.withOpacity(0.12)
                      : colors.primaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? Icons.check_circle : step.icon,
                  color: colors.primary,
                  size: GetStartedGuideStyle.stepIconSize,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              if (!done && step.onAction != null)
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      step.onAction?.call();
                      _markDone(index);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Text(step.actionLabel),
                  ),
                ),
              if (!done && step.onAction != null) const SizedBox(width: 8),
              if (done)
                Expanded(
                  child: Text(
                    l10n.getStartedStepDone,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () => _markDone(index),
                  child: Text(l10n.getStartedMarkDone),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDots(dynamic colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.steps.length, (i) {
        final active = i == _currentPage;
        final done = _completed.contains(i);
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: GetStartedGuideStyle.dotSpacing / 2,
          ),
          width: GetStartedGuideStyle.dotSize,
          height: GetStartedGuideStyle.dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? colors.primary
                : active
                ? colors.primary.withOpacity(0.5)
                : colors.outline.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
