import 'package:twake_chat/pages/bootstrap/verify_device_view_style.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

/// Wraps [content] in the web centered-modal chrome on wide screens and the
/// mobile bottom-sheet chrome on narrow ones — shared by every step of the
/// bootstrap/verify-device flow so all mobile screens are bottom sheets.
class BootstrapModalChrome extends StatelessWidget {
  final Widget content;
  final VoidCallback? onClose;

  final bool forceCenteredDialog;

  const BootstrapModalChrome({
    super.key,
    required this.content,
    this.onClose,
    this.forceCenteredDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final useMobileSheet =
        ResponsiveUtils().isMobile(context) && !forceCenteredDialog;
    return useMobileSheet
        ? _MobileSheet(content: content, onClose: onClose)
        : _WebModal(content: content, onClose: onClose);
  }
}

class _WebModal extends StatelessWidget {
  final Widget content;
  final VoidCallback? onClose;

  const _WebModal({required this.content, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: VerifyDeviceViewStyle.webModalWidth,
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: VerifyDeviceViewStyle.closeButtonInset * 2,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: VerifyDeviceViewStyle.webModalPadding,
                decoration: BoxDecoration(
                  color: VerifyDeviceViewStyle.backgroundColorOf(context),
                  borderRadius: BorderRadius.circular(
                    VerifyDeviceViewStyle.webModalRadius,
                  ),
                  boxShadow: VerifyDeviceViewStyle.webModalShadow,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: VerifyDeviceViewStyle.webContentWidth,
                  ),
                  child: content,
                ),
              ),
              if (onClose != null)
                Positioned(
                  top: VerifyDeviceViewStyle.closeButtonInset,
                  right: VerifyDeviceViewStyle.closeButtonInset,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileSheet extends StatefulWidget {
  final Widget content;
  final VoidCallback? onClose;

  const _MobileSheet({required this.content, this.onClose});

  @override
  State<_MobileSheet> createState() => _MobileSheetState();
}

class _MobileSheetState extends State<_MobileSheet>
    with SingleTickerProviderStateMixin {
  /// Fraction of the sheet's own height the user must drag down (or drag
  /// fast enough downward) before it's treated as a dismiss instead of
  /// snapping back.
  static const double _dismissDragFraction = 0.3;
  static const double _dismissFlingVelocity = 700;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..addListener(() => setState(() {}));

  double _sheetHeight = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_sheetHeight <= 0) return;
    final next = (_controller.value + details.delta.dy / _sheetHeight).clamp(
      0.0,
      1.0,
    );
    _controller.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    final shouldDismiss =
        _controller.value > _dismissDragFraction ||
        details.velocity.pixelsPerSecond.dy > _dismissFlingVelocity;
    if (shouldDismiss) {
      _controller.animateTo(1, curve: Curves.easeOut).whenComplete(() {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      _controller.animateTo(0, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Avoids a transparent gap above the iOS home indicator.
      extendBody: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionalTranslation(
            translation: Offset(0, _controller.value),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: VerifyDeviceViewStyle.backgroundColorOf(context),
                  borderRadius: VerifyDeviceViewStyle.sheetRadius,
                ),
                child: SafeArea(
                  top: false,
                  bottom: PlatformInfos.isAndroid,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DragHandle(onClose: widget.onClose),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: VerifyDeviceViewStyle.sheetContentPadding,
                          child: _MeasureSize(
                            onChange: (size) => _sheetHeight = size.height,
                            child: widget.content,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.child, required this.onChange});

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  final _key = GlobalKey();
  Size? _lastSize;

  void _reportIfChanged() {
    final size = _key.currentContext?.size;
    if (size == null || size == _lastSize) return;
    _lastSize = size;
    widget.onChange(size);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportIfChanged());
    return SizedBox(key: _key, child: widget.child);
  }
}

class _DragHandle extends StatelessWidget {
  final VoidCallback? onClose;

  const _DragHandle({this.onClose});

  @override
  Widget build(BuildContext context) {
    final handle = Container(
      width: VerifyDeviceViewStyle.dragHandleWidth,
      height: VerifyDeviceViewStyle.dragHandleHeight,
      decoration: BoxDecoration(
        color: LinagoraStateLayer(
          Theme.of(context).colorScheme.surfaceTint,
        ).opacityLayer3,
        borderRadius: BorderRadius.circular(
          VerifyDeviceViewStyle.dragHandleHeight,
        ),
      ),
    );
    return Padding(
      padding: VerifyDeviceViewStyle.dragHandlePadding,
      child: onClose == null
          ? handle
          : GestureDetector(onTap: onClose, child: handle),
    );
  }
}
