# 23. Upgrade flutter 3.22

Date: 2024-05-24

## Status

Accepted

## Context

We need to upgrade the flutter to have up-to-date performance and features

## Decision

- Add `ignore_deprecated` and `TODO` for `background` and `onBackground` color, when `surface` and `background` merge to one, we will change
- change name from `surfaceVariant` => `surfaceContainerHighest`, `MaterialStateProperty` => `WidgetStateProperty`, `MaterialState` => `WidgetState`, use `super.key` for shorter form (new lint rule)
- Migration from `RawKeyEvent` to `KeyEvent`. [Read more](https://docs.flutter.dev/release/breaking-changes/key-event-migration#deprecated-apis-that-have-an-equivalent) (in conclusion, add ignore_deprecated, because that when i test it again, the up/down not work)
- Upgrade flutter_local_notification from `requestPermission` => `requestNotificationsPermission` [Changelog](https://pub.dev/packages/flutter_local_notifications/changelog#16001), [Readmore](https://developer.android.com/develop/ui/views/notifications/notification-permission?hl=vi)
- Upgrade `url_laucher`, change from `Uri` to `WebUri`, remove `ChromeSafariBrowserSettings` in web
- Upgrade `the index.html` file in web folder
- Upgrade other packages in pubspec.yaml to resolve conflicts