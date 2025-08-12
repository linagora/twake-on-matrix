# 25. Flutter 3.24.0 Upgrade

**Date:** 2024-08-26

## Status

**Accepted**

## Context

To enable features like text pasting without requiring user permission on iOS, we need to upgrade to Flutter 3.24.0.[See detail](https://github.com/flutter/flutter/issues/103163#issuecomment-2320611190)

## Decision

During the upgrade to Flutter 3.24.0, some dependencies must also be updated to ensure successful release builds. Specifically, the `compileSdkVersion` needs to be updated to at least 31. Below is the list of packages that require a minimum `compileSdkVersion` of 31 or higher for successful compilation:

- **`callkeep`**: Upgrade `compileSdkVersion` from 28 to 31. [See PR #190](https://github.com/flutter-webrtc/callkeep/pull/190)
- **`receive_sharing_intent`**: Switch to the version maintained by Linagora, which has `compileSdkVersion` set to 33. [See Linagora Repository](https://github.com/linagora/receive_sharing_intent)
- **`flutter_contacts`**: Upgrade `compileSdkVersion` from 31 to 33. [See PR #11](https://github.com/linagora/flutter_contacts/pull/11)
- **`fcm_shared_isolate`**: [See Merge Request](https://gitlab.com/famedly/company/frontend/libraries/fcm_shared_isolate/-/merge_requests/10)
- **`native_image`**: [See Merge Request](https://gitlab.com/famedly/company/frontend/libraries/native_imaging/-/merge_requests/22)
- **`flutter_app_badger`**: [See PR #92](https://github.com/g123k/flutter_app_badger/pull/92)
- **`image_gallery_saver`**: [See GitHub Repository](https://github.com/FlutterStudioIst/image_gallery_saver.git)

Additionally, update `@UIApplicationMain` to `@main` in the codebase. For more information, refer to [Swift Evolution Proposal #0383](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0383-deprecate-uiapplicationmain-and-nsapplicationmain.md).

The build debug version of window platform has not been success, due to the error tracking here: https://github.com/firebase/flutterfire/issues/12051.
