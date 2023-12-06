# 12. Improve iOS notification

Date: 2023-12-06

## Status

Accepted

## Context
The motivation behind this decision is the inability to execute Dart code for decrypting notifications when the iOS app is running in the background. This limitation is different from Android or Web, where Dart code can easily run in such scenarios.

## Decision
We have decided to make the following changes to address the mentioned issue:

1. **Notification Service Extension (NSE):**
   - Utilize the [Notification Service Extension](https://developer.apple.com/documentation/usernotifications/modifying_content_in_newly_delivered_notifications) provided by Apple to modify the content of notifications.

2. **MatrixRustSDK Integration:**
   - Integrate MatrixRustSDK to decrypt messages within the Notification Service Extension. The MatrixRustSDK version and other dependencies should be synchronized with Element X to avoid unexpected errors. Reference the synchronization from [Element X project.yml](https://github.com/vector-im/element-x-ios/blob/main/project.yml#L46).

3. **Automated Script for Source Code Copy:**
   - Develop a script written in Node.js to automate the process of copying the entire source code related to the Notification Service Extension from Element X, a known version. Detail at [scripts/copy-nse/README.MD](../../scripts/copy-nse/README.MD)

4. **Dart Code Adjustment:**
   - Modify Dart code to ensure compatibility with the Notification Service Extension from Element X.

5. **Debugging Patch with AppDelegate:**
   - Add the patch `scripts/patchs/ios-extension-debug.patch` to address debugging issues. This patch removes FlutterAppDelegate and suggests using AppDelegate instead for smoother debugging during Notification Service Extension development.

6. **Add pusher_notification_client_identifier to Default Payload:**
   - Extend the default notification payload by adding the `pusher_notification_client_identifier` field. This supports multi-account scenarios, where each notification will have a `client_identifier` to identify the user for decryption. For now it is SHA256 of userId

7. **Keychain Access Groups:**
   - Utilize `keychain-access-groups` to enable data exchange between the Notification Service Extension (NSE) and the main app by using a shared Keychain Access Group. This ensures security and safe data transmission (See details at [link](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps/)).

8. **INSendMessageIntent:**
   - Use `INSendMessageIntent` to support displaying profile pictures in notifications. Instead of using regular notifications, integrating `INSendMessageIntent` ensures that the sender's image is displayed correctly in the notification (See details at [link](https://stackoverflow.com/questions/68198452/ios-15-communication-notification-picture-not-shown)).

9. **iOS Version Support Below 16:**
   - Communicate that Element X's Notification Service Extension supports iOS 16 and above. Therefore, Twake NSE will also have a similar requirement. Users with iOS versions below 16 can still install Twake, but they won't be able to decrypt notifications.

## Consequences
Implementing these decisions has the following consequences:

1. **Notification Discrepancy:**
   - Notifications will behave differently in the background and foreground because they are handled by Swift in the background and Dart in the foreground.

2. **Integration Challenges:**
   - There might be challenges in seamlessly integrating Notification Service Extension with MatrixRustSDK and adjusting it to fit the current source code. The MatrixRustSDK version and dependencies should be synchronized with Element X to avoid unexpected errors.

3. **Automated Source Code Copy:**
   - Introducing an automated Node.js script streamlines the process of copying the source code from Element X, enhancing efficiency and reducing manual errors during this task.

4. **Message Decryption Research:**
   - Further research is required to successfully decrypt encrypted messages. This introduces a potential risk as it may involve understanding specific nuances when integrating MatrixRustSDK with Notification Service Extension.

5. **Maintenance Overhead:**
   - Copying source code from Element X may create maintenance overhead, as any updates or changes in Element X's source code need manual integration and synchronization.

6. **Improved Debugging:**
   - The debugging patch aims to optimize the debugging experience by addressing issues related to FlutterAppDelegate in the context of Notification Service Extension.

7. **Multi-Account Support:**
   - Multi-account support is achieved by adding `pusher_notification_client_identifier` to the default notification payload.

8. **Security with Keychain Access Groups:**
   - Ensures secure data transmission between Notification Service Extension and the main app using Keychain Access Groups.

9. **Profile Picture Display Enhancement:**
   - The use of `INSendMessageIntent` enhances the user experience by ensuring the correct display of sender profile pictures in notifications.

10. **iOS 16 Requirement:**
    - Communicates that Element X's Notification Service Extension requires iOS 16 or later, and Twake NSE has a similar requirement. Users below iOS 16 can install Twake but won't decrypt notifications.
