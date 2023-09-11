# 5. Push rules decision
Date: 2023-09-11

## Status

Accepted

## Context

In the Matrix protocol, push rules define how messages are filtered and displayed on devices. These rules are customizable through APIs, allowing us to enable, disable, and specify actions for each rule. Furthermore, there are various types of push rules (override, content, sender, underride, etc.), each serving different purposes and enabling the configuration of push notifications. For reference, see the [Matrix Push Rules Specification](https://spec.matrix.org/v1.8/client-server-api/#push-rules). However, push rules have exhibited several limitations. For instance, notifications for group chats may still be received by users even after they have disabled them ([example](https://photos.app.goo.gl/JoaysSunovsdPtAs8)).

## Decision

To address these limitations, we propose the introduction of optional custom fields within the content of events. These custom fields can be utilized in the future to create custom push rules. For example, the `setName()` API for rooms lacks the capability for clients to determine whether the room already exists. To mitigate this, we suggest adding a custom field, such as `'roomState': 'created'`, to the content of `setName()` APIs. Subsequently, this `roomState` custom field can be utilized as a condition within push rules. To maintain consistency and facilitate tracking, we recommend defining metadata custom fields exclusively and documenting them in a constants file for easy reference by other developers.

## Consequences

- **Advantages:**
  - Simplifies the definition of push rules, enhancing clarity and organization.
  - Provides flexibility to define customized push rules.
  - Promotes extendability and maintainability.
  - Compatible with various home servers.

- **Disadvantages:**
  - Push notifications may behave inconsistently across different client applications. In essence, push rules are optimized for Twake applications and may not offer consistent behavior in other environments. For instance, in the Element application, notifications may be displayed for actions such as message sending or group name changes, regardless of user preferences regarding name change notifications.
