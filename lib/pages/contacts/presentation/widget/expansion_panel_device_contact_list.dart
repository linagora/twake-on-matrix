import 'package:fluffychat/pages/contacts/presentation/widget/expansion_panel_contact_list.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ExpansionPanelDeviceContactList extends StatefulWidget {

  final ExpansionPanelContactList child;

  const ExpansionPanelDeviceContactList({
    super.key,
    required this.child
  });

  @override
  State<StatefulWidget> createState() => _ExpansionPanelDeviceContactListState();
}

class _ExpansionPanelDeviceContactListState extends State<ExpansionPanelDeviceContactList> {

  final Permission _permission = Permission.contacts;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  PermissionStatus get  status => _permissionStatus;

  @override
  void initState() {
    super.initState();
    requestPermission();
    _listenForPermissionStatus();
  }

  void _listenForPermissionStatus() async {
    final status = await _permission.status;
    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> requestPermission() async {
    if (await Permission.contacts.isPermanentlyDenied) {
      setState(() {
        _permissionStatus = PermissionStatus.permanentlyDenied;
      });
      return ;
    }

    final status = await _permission.request();

    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> requestPermissionInSettings() async {
    if (await _permission.isPermanentlyDenied) {
      final isOpen = await openAppSettings();
      if (isOpen) {
        setState(() {
          _permissionStatus = status;
          _permissionStatus = PermissionStatus.denied;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionStatus == PermissionStatus.permanentlyDenied) {
      return TextButton(
        onPressed: () async => requestPermissionInSettings.call(),
        child: const Text('Request permission in Settings'));
    }
    
    return widget.child;
  }
}