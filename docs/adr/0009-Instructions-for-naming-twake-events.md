# 9. Instructions for naming twake events

Date: 2023-10-03

## Status

Accepted

## Docs

- [Spec](https://spec.matrix.org/v1.6/#events)

## Context

- All data exchanged through Matrix is represented as an “event”. In addition, we have local support events.
- We can use local events to handle logic and behavior by injecting events into a defined stream.

## Decision

How to name events
- Below are the naming rules for events.
- App.twake is the name of the application.
- Inapp is event use for local support.
- Profile is the name of the feature.
- Avatar is the name of the event.
 ex: 'app.twake.inapp.profile.avatar'   

How to use events.
- Send event

```
class TwakeEventDispatcher {
  static final TwakeEventDispatcher _twakeEventDispatcher =
      TwakeEventDispatcher._instance();

  factory TwakeEventDispatcher() {
    return _twakeEventDispatcher;
  }

  TwakeEventDispatcher._instance();

  void sendAccountDataEvent({
    required Client client,
    required BasicEvent basicEvent,
  }) {
    client.onAccountData.add(basicEvent);
  }
}

twakeEventDispatcher.sendAccountDataEvent(
      client: client,
      basicEvent: BasicEvent(
        type: TwakeInappEventTypes.uploadAvatarEvent,
        content: profile.toJson(),
      ),
    );
```
- Listen event and handle it

```
client.onAccountData.stream.listen((event) {
      Logs().d(
        'FetchProfileMixin::onAccountData() - EventType: ${event.type} - EventContent: ${event.content}',
      );
      if (event.type == TwakeInappEventTypes.uploadAvatarEvent) {
        profileNotifier.value = Profile.fromJson(event.content);
      }
    });
```

## Consequences

- If we do not specifically define the event, it will be duplicated with the homeserver event