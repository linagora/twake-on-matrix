import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/di/di_interface.dart';
import 'package:flutter/material.dart';
import 'package:vrouter/vrouter.dart';


class VWidgetWithDependency extends VGuard {

  final String? path;

  /// A name for the route which will allow you to easily navigate to it
  /// using [VRouter.of(context).pushNamed]
  ///
  /// Note that [name] should be unique w.r.t every [VRouteElement]
  final String? name;

  /// Alternative paths that will be matched to this route
  ///
  /// Note that path is match first, then every aliases in order
  final List<String> aliases;

  /// The widget which will be displayed for this [VRouteElement]
  final Widget widget;

  /// A LocalKey that will be given to the page which contains the given [widget]
  ///
  /// This key mostly controls the page animation. If a page remains the same but the key is changes,
  /// the page gets animated
  /// The key is by default the value of the current [path] (or [aliases]) with
  /// the path parameters replaced
  ///
  /// Do provide a constant [key] if you don't want this page to animate even if [path] or
  /// [aliases] path parameters change
  final LocalKey? key;

  /// The duration of [VWidgetBase.buildTransition]
  final Duration? transitionDuration;

  /// The reverse duration of [VWidgetBase.buildTransition]
  final Duration? reverseTransitionDuration;

  /// Create a custom transition effect when coming to and
  /// going to this route
  /// This has the priority over [VRouter.buildTransition]
  ///
  /// Also see:
  ///   * [VRouter.buildTransition] for default transitions for all routes
  final Widget Function(Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child)? buildTransition;

  /// Whether this page route is a full-screen dialog.
  ///
  /// In Material and Cupertino, being fullscreen has the effects of making the app bars
  /// have a close button instead of a back button. On iOS, dialogs transitions animate
  /// differently and are also not closeable with the back swipe gesture.
  final bool fullscreenDialog;

  final DIInterface di;

  final OnFinishedBind? onFinishedBind;

  @override
  Future<void> beforeEnter(VRedirector vRedirector) async {
    super.beforeEnter(vRedirector);
    if (beforeDI != null) {
      beforeDI!.call(vRedirector);
    }
    di.bind(onFinishedBind: onFinishedBind);
  }

  final Future<void> Function(VRedirector vRedirector)? beforeDI;

  @override
  Future<void> beforeUpdate(VRedirector vRedirector) =>
      _beforeUpdate(vRedirector);
  final Future<void> Function(VRedirector vRedirector) _beforeUpdate;

  @override
  Future<void> beforeLeave(VRedirector vRedirector,
    void Function(Map<String, String> state) saveHistoryState) async {
      super.beforeLeave(vRedirector, saveHistoryState);
      await di.unbind();
    }
  
  @override
  void afterEnter(BuildContext context, String? from, String to) =>
      _afterEnter(context, from, to);
  final void Function(BuildContext context, String? from, String to)
      _afterEnter;

  @override
  void afterUpdate(BuildContext context, String? from, String to) =>
      _afterUpdate(context, from, to);
  final void Function(BuildContext context, String? from, String to)
      _afterUpdate;

  
  VWidgetWithDependency({
    required this.path,
    required this.widget,
    this.beforeDI,
    required this.di,
    this.onFinishedBind,
    super.beforeEnter,
    super.beforeUpdate,
    super.afterEnter,
    super.afterUpdate,
    super.stackedRoutes = const [],
    this.key,
    this.name,
    this.aliases = const [],
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.buildTransition,
    this.fullscreenDialog = false,
  }): _beforeUpdate = beforeUpdate,
      _afterEnter = afterEnter,
      _afterUpdate = afterUpdate;

  @override
  List<VRouteElement> buildRoutes() => [
    VPath(
      path: path,
      aliases: aliases,
      mustMatchStackedRoute: mustMatchStackedRoute,
      stackedRoutes: [
        VWidgetBase(
          widget: widget,
          key: key,
          name: name,
          stackedRoutes: stackedRoutes,
          buildTransition: buildTransition,
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
          fullscreenDialog: fullscreenDialog,
        ),
      ],
    ),
  ];

  /// A boolean to indicate whether this can be a valid [VRouteElement] of the [VRoute] if no
  /// [VRouteElement] in its [stackedRoute] is matched
  ///
  /// This is mainly useful for [VRouteElement]s which are NOT [VRouteElementWithPage]
  bool get mustMatchStackedRoute => false;
}