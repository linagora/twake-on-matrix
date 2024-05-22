import 'package:fluffychat/presentation/mixins/connect_page_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/connect/connect_page_view.dart';
import 'package:fluffychat/widgets/matrix.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => ConnectPageController();
}

class ConnectPageController extends State<ConnectPage> with ConnectPageMixin {
  final TextEditingController usernameController = TextEditingController();

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
