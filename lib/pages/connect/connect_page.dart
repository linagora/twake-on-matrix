import 'package:fluffychat/pages/connect/connect_page_mixin.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/connect/connect_page_view.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({Key? key}) : super(key: key);

  @override
  State<ConnectPage> createState() => ConnectPageController();
}

class ConnectPageController extends State<ConnectPage> with ConnectPageMixin {
  final TextEditingController usernameController = TextEditingController();
  String? signupError;
  bool loading = false;

  void pickAvatar() async {
    final source = !PlatformInfos.isMobile
        ? ImageSource.gallery
        : await showModalActionSheet<ImageSource>(
            context: context,
            title: L10n.of(context)!.changeYourAvatar,
            actions: [
              SheetAction(
                key: ImageSource.camera,
                label: L10n.of(context)!.openCamera,
                isDefaultAction: true,
                icon: Icons.camera_alt_outlined,
              ),
              SheetAction(
                key: ImageSource.gallery,
                label: L10n.of(context)!.openGallery,
                icon: Icons.photo_outlined,
              ),
            ],
          );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 512,
      maxHeight: 512,
    );
    setState(() {
      Matrix.of(context).loginAvatar = picked;
    });
  }

  void signUp() async {
    usernameController.text = usernameController.text.trim();
    final localpart =
        usernameController.text.toLowerCase().replaceAll(' ', '_');
    if (localpart.isEmpty) {
      setState(() {
        signupError = L10n.of(context)!.pleaseChooseAUsername;
      });
      return;
    }

    setState(() {
      signupError = null;
      loading = true;
    });

    try {
      try {
        await Matrix.of(context).getLoginClient().register(username: localpart);
      } on MatrixException catch (e) {
        if (!e.requireAdditionalAuthentication) rethrow;
      }
      setState(() {
        loading = false;
      });
      Matrix.of(context).loginUsername = usernameController.text;
      context.go('/signup');
    } catch (e, s) {
      Logs().d('Sign up failed', e, s);
      setState(() {
        signupError = e.toLocalizedString(context);
        loading = false;
      });
    }
  }

  void login() => context.go('/login');

  Map<String, dynamic>? rawLoginTypes;

  @override
  void initState() {
    super.initState();
    if (supportsSso(context)) {
      Matrix.of(context)
          .getLoginClient()
          .request(
            RequestType.GET,
            '/client/r0/login',
          )
          .then(
            (loginTypes) => setState(() {
              rawLoginTypes = loginTypes;
            }),
          );
    }
  }

  @override
  Widget build(BuildContext context) => ConnectPageView(this);
}

class IdentityProvider {
  final String? id;
  final String? name;
  final String? icon;
  final String? brand;

  IdentityProvider({this.id, this.name, this.icon, this.brand});

  factory IdentityProvider.fromJson(Map<String, dynamic> json) =>
      IdentityProvider(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        brand: json['brand'],
      );
}
