import 'package:fluffychat/pages/bootstrap/verify_device_view_style.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

/// Wraps [content] in the web centered-modal chrome on wide screens and the
/// mobile bottom-sheet chrome on narrow ones — shared by every step of the
/// bootstrap/verify-device flow so all mobile screens are bottom sheets.
class BootstrapModalChrome extends StatelessWidget {
  final Widget content;
  final VoidCallback? onClose;

  const BootstrapModalChrome({super.key, required this.content, this.onClose});

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils().isMobile(context)
        ? _MobileSheet(content: content)
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
        child: SizedBox(
          width: VerifyDeviceViewStyle.webModalWidth,
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
                child: SizedBox(
                  width: VerifyDeviceViewStyle.webContentWidth,
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

class _MobileSheet extends StatelessWidget {
  final Widget content;

  const _MobileSheet({required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Avoids a transparent gap above the iOS home indicator.
      extendBody: true,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: VerifyDeviceViewStyle.backgroundColorOf(context),
            borderRadius: VerifyDeviceViewStyle.sheetRadius,
          ),
          child: SafeArea(
            top: false,
            // Android needs bottom inset for the system nav bar; iOS home
            // indicator should not add an empty band under the button.
            bottom: PlatformInfos.isAndroid,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DragHandle(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: VerifyDeviceViewStyle.sheetContentPadding,
                    child: content,
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VerifyDeviceViewStyle.dragHandlePadding,
      child: Container(
        width: VerifyDeviceViewStyle.dragHandleWidth,
        height: VerifyDeviceViewStyle.dragHandleHeight,
        decoration: BoxDecoration(
          color: LinagoraStateLayer(
            LinagoraSysColors.material().surfaceTintDark,
          ).opacityLayer3,
          borderRadius: BorderRadius.circular(
            VerifyDeviceViewStyle.dragHandleHeight,
          ),
        ),
      ),
    );
  }
}
