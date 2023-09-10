# Twake
![](https://github.com/linagora/twake-on-matrix/assets/6462404/76e7795e-39b6-4667-a313-4068afadb1ed)

<p>
  <a href="https://hosted.weblate.org/projects/linagora/twake-matrix/#repository" target="new">Translate Twake</a>
 </p>


FluffyChat is an open source, nonprofit and cute matrix messenger app. The app is easy to use but secure and decentralized.

## Features

- Send all kinds of messages, images and files
- Voice messages
- Location sharing
- Push notifications
- Unlimited private and public group chats
- Public channels with thousands of participants
- Feature rich group moderation including all matrix features
- Discover and join public groups
- Dark mode
- Custom themes
- Hides complexity of Matrix IDs behind simple QR codes
- Custom emotes and stickers
- Spaces
- Compatible with Element, Nheko, NeoChat and all other Matrix apps
- End to end encryption
- Emoji verification & cross signing
- And much more...

## Setup

### Flutter
```
  flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
```

### Add commit hook to format and code analyze
```
  bash scrips/config-pre-commit.sh
```

# Special thanks

* <a href="https://github.com/fabiyamada">Fabiyamada</a> is a graphics designer from Brasil and has made the fluffychat logo and the banner. Big thanks for her great designs.

* <a href="https://github.com/advocatux">Advocatux</a> has made the Spanish translation with great love and care. He always stands by my side and supports my work with great commitment.

* Thanks to MTRNord and Sorunome for developing.

* Also thanks to all translators and testers! With your help, fluffychat is now available in more than 12 languages.

* <a href="https://github.com/googlefonts/noto-emoji/">Noto Emoji Font</a> for the awesome emojis.

* <a href="https://github.com/madsrh/WoodenBeaver">WoodenBeaver</a> sound theme for the notification sound.

* The Matrix Foundation for making and maintaining the [emoji translations](https://github.com/matrix-org/matrix-doc/blob/main/data-definitions/sas-emoji.json) used for emoji verification, licensed Apache 2.0
