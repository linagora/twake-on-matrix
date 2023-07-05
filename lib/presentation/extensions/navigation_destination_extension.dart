import 'package:flutter/material.dart';

extension NavigationDestinationExtension on NavigationDestination {
  NavigationRailDestination toNavigationRail({EdgeInsetsGeometry? padding}) {
    return NavigationRailDestination(
      icon: icon, 
      label: Text(label),
      selectedIcon: selectedIcon,
      padding: padding,
    );
  }
}