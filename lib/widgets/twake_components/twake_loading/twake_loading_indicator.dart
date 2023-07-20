import 'package:fluffychat/widgets/twake_components/twake_loading/status_loading_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';

class TwakeLoadingIndicator extends StatefulWidget {
  final bool showIndicator;
  final Color flashingCircleDarkColor;
  final Color flashingCircleBrightColor;

  const TwakeLoadingIndicator({
    super.key,
    this.showIndicator = false,
    this.flashingCircleDarkColor = const Color(0xFF0A84FF),
    this.flashingCircleBrightColor = const Color(0xFFaec1dd),
  });

  @override
  State<TwakeLoadingIndicator> createState() => _TwakeLoadingIndicatorState();
}

class _TwakeLoadingIndicatorState extends State<TwakeLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;

  late AnimationController _repeatingController;
  final List<Interval> _dotIntervals = const [
    Interval(0.0, 0.5),
    Interval(0.2, 0.6),
    Interval(0.4, 0.7),
  ];

  @override
  void initState() {
    super.initState();

    _appearanceController = AnimationController(
      vsync: this,
    )..addListener(() {
        setState(() {});
      });

    _repeatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.showIndicator) {
      _showIndicator();
    }
  }

  @override
  void didUpdateWidget(TwakeLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showIndicator != oldWidget.showIndicator) {
      if (widget.showIndicator) {
        _showIndicator();
      } else {
        _hideIndicator();
      }
    }
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _repeatingController.dispose();
    super.dispose();
  }

  void _showIndicator() {
    _appearanceController
      ..duration = const Duration(milliseconds: 750)
      ..forward();
    _repeatingController.repeat();
  }

  void _hideIndicator() {
    _appearanceController
      ..duration = const Duration(milliseconds: 150)
      ..reverse();
    _repeatingController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StatusLoading(
        repeatingController: _repeatingController,
        dotIntervals: _dotIntervals,
        flashingCircleDarkColor: widget.flashingCircleDarkColor,
        flashingCircleBrightColor: widget.flashingCircleBrightColor,
      ),
    );
  }
}
