import 'package:flutter/material.dart';
import 'package:twake_chat/pages/app_grid/app_grid_dashboard_view.dart';

class AppGridDashboard extends StatefulWidget {
  const AppGridDashboard({super.key});

  @override
  State<AppGridDashboard> createState() => AppGridDashboardState();
}

/// Holds the ephemeral UI state of the app grid button: whether the grid is
/// open and the hover colors. The apps come from
/// `appGridDashboardControllerProvider`.
class AppGridDashboardState extends State<AppGridDashboard> {
  final isOpenAppGridDashboardNotifier = ValueNotifier<bool>(false);

  final hoverColorAppGrid = ValueNotifier<Color>(Colors.transparent);

  final hoverColorAppHelp = ValueNotifier<Color>(Colors.transparent);

  void hideAppGridDashboard() {
    if (!mounted) return;
    if (isOpenAppGridDashboardNotifier.value == false) return;
    isOpenAppGridDashboardNotifier.value = false;
  }

  @override
  void deactivate() {
    // Close the portal before deactivation to prevent accessing
    // the Overlay context after the widget is deactivated
    hideAppGridDashboard();
    super.deactivate();
  }

  @override
  void dispose() {
    isOpenAppGridDashboardNotifier.dispose();
    hoverColorAppGrid.dispose();
    hoverColorAppHelp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppGridDashboardView(controller: this);
  }
}
