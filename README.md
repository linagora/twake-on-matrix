# Twake
[![Contributors](https://img.shields.io/github/contributors/linagora/twake-on-matrix?label=Contributors
)](
  https://github.com/linagora/twake-on-matrix/graphs/contributors
)
[![Issues](https://img.shields.io/github/issues/linagora/twake-on-matrix?label=Issues
)](https://github.com/linagora/twake-on-matrix/issues)
[![Documentation](https://img.shields.io/badge/Documentation-green.svg)](docs)
[![Android application](https://img.shields.io/badge/App-Android-blue.svg)](https://play.google.com/store/apps/dev?id=8845244706987756601)
[![Ios application](https://img.shields.io/badge/App-iOS-red.svg)](https://apps.apple.com/gr/developer/linagora/id1110867042)

<br />
<div align="center">
  <a href="https://github.com/linagora/twake-on-matrix">
    <img src="https://github.com/linagora/twake-on-matrix/assets/48354990/cda56167-f070-4064-90fb-81be7d20ab27">
  </a>

  <p align="center">
    <a href="https://beta.twake.app/web/#/rooms">View Demo</a>
    •
    <a href="https://github.com/linagora/twake-on-matrix/issues">Report Bug</a>
    •
    <a href="https://hosted.weblate.org/projects/linagora/twake-matrix/#repository">Translate Twake</a>
  </p>
</div>

Twake is an open source, nonprofit and cute matrix messenger app developed by [Linagora](https://linagora.com). The app is easy to use but secure and decentralized.

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
```bash
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
```

### Add commit hook to format and code analyze
```bash
bash scripts/config-pre-commit.sh
```

# Special thanks
* <a href="https://github.com/krille-chan/fluffychat">FluffyChat</a> is the original repository of this project. A huge thanks to the upstream repository for their vital contributions, not only for this project but also for [Matrix SDK in Dart](https://github.com/famedly/matrix-dart-sdk)

* <a href="https://github.com/fabiyamada">Fabiyamada</a> is a graphics designer from Brasil and has made the fluffychat logo and the banner. Big thanks for her great designs.

* <a href="https://github.com/advocatux">Advocatux</a> has made the Spanish translation with great love and care. He always stands by my side and supports my work with great commitment.

* Thanks to MTRNord and Sorunome for developing.

* Also thanks to all translators and testers! With your help, fluffychat is now available in more than 12 languages.

* <a href="https://github.com/googlefonts/noto-emoji/">Noto Emoji Font</a> for the awesome emojis.

* <a href="https://github.com/madsrh/WoodenBeaver">WoodenBeaver</a> sound theme for the notification sound.

* The Matrix Foundation for making and maintaining the [emoji translations](https://github.com/matrix-org/matrix-doc/blob/main/data-definitions/sas-emoji.json) used for emoji verification, licensed Apache 2.0
