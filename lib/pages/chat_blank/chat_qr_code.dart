import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatQrCode extends StatefulWidget {
  const ChatQrCode({super.key});

  @override
  State<ChatQrCode> createState() => _ChatQrCodeState();
}

class _ChatQrCodeState extends State<ChatQrCode> {
  @protected
  late QrCode qrCode;

  @protected
  late QrImage qrImage;

  @protected
  late PrettyQrDecoration decoration;

  @override
  void initState() {
    super.initState();

    qrCode = QrCode.fromData(
      data: AppConfig.qrCodeDownloadUrl,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );

    qrImage = QrImage(qrCode);

    decoration = PrettyQrDecoration(
      image: PrettyQrDecorationImage(
        image: AssetImage(ImagePaths.logoPng),
        position: PrettyQrDecorationImagePosition.embedded,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    Matrix.of(context).resetFirstLogin();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 36,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    UrlLauncher(
                      context,
                      url: AppConfig.twakeChatGooglePlay,
                    ).launchUrl();
                  },
                  child: SvgPicture.asset(
                    ImagePaths.googlePlay,
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () {
                    UrlLauncher(
                      context,
                      url: AppConfig.twakeChatAppleStore,
                    ).launchUrl();
                  },
                  child: SvgPicture.asset(
                    ImagePaths.appStore,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            height: 200,
            child: TweenAnimationBuilder<PrettyQrDecoration>(
              tween: PrettyQrDecorationTween(
                begin: decoration,
                end: decoration,
              ),
              curve: Curves.ease,
              duration: const Duration(
                milliseconds: 240,
              ),
              builder: (context, decoration, child) {
                return PrettyQrView(
                  qrImage: qrImage,
                  decoration: decoration,
                );
              },
            ),
          ),
          Container(
            constraints: const BoxConstraints(
              maxWidth: ResponsiveUtils.bodyRadioWidth,
            ),
            padding: const EdgeInsets.only(
              top: 16,
              left: 24,
              right: 24,
            ),
            child: Text(
              L10n.of(context)!.scanQrCodeToJoin,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
