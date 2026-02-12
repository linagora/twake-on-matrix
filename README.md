# Twake Chat Client
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
     <img src="https://github.com/linagora/twake-on-matrix/assets/146178981/3e395e0e-5796-4986-97ab-814ae28745b2">
  </a>



  <p align="center">
    <a href="https://twake-chat.com">Website</a>
    •
    <a href="https://beta.twake.app/web/#/rooms">View Demo</a>
    •
    <a href="https://github.com/linagora/twake-on-matrix/issues">Report Bug</a>
    •
    <a href="https://github.com/orgs/linagora/projects/6/views/5">Roadmap</a>
    •
    <a href="https://hosted.weblate.org/projects/linagora/twake-matrix/#repository">Translate Twake</a>
  </p>
</div>

Twake Chat is an open source, decentralized chat app based on the Matrix protocol. It was developed by [Linagora](https://linagora.com). Twake Chat is a good option for individuals and organizations who are looking for a secure and decentralized chat app. It is also a good choice for developers who want to build their own Matrix-based chat apps.

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

## Development

Please make sure to run the following command at first, to verify your code before each commit:

```bash
bash scripts/config-pre-commit.sh
```
### Requirements

- [ ] Flutter 3.38.9

You can at any moment verify your flutter installation using:

```bash
flutter doctor -v
```

#### Web

If you only plan to work on the `web` target we recommend installing Google Chrome as it is the default supported target *(Flutter being developped by Google)*.

It is also **required** to have a web ready version of libolm available in the `assets/js/package` folder. You can build a version using:

```bash
docker run -v ./assets/js/package:/package nixos/nix:2.22.1

# within the docker
nix build -v --extra-experimental-features flakes --extra-experimental-features nix-command gitlab:matrix-org/olm/3.2.16?host=gitlab.matrix.org\#javascript
cp /result/javascript/* /package/. -v
exit

# back on your host
sudo chown $(id -u):$(id -g) ./assets/js/package -Rv
```
#### Android

- [ ] An implementation of JDK 17 *(tested with openjdk-17.0.13+11)*
- [ ] (Optional) Android Studio
- [ ] An Android SDK with:
  - [ ] Android build tools: 34.0.0
  - [ ] Android platform: 31, 32, 33, 34, 35
  - [ ] CMake: 3.22.1
  - [ ] Android NDK: 26.1.10909125
  - [ ] Google APIs: enabled

*Note: Gradle will try to install the JDK 8. If for any reasons the operation failed, try to install your own and use [this method](https://github.com/pm-McFly/twake-on-matrix/issues/1#issuecomment-2581428804) to tell Gradle where to find it.*

#### Linux

- [ ] Lib JsonCPP
- [ ] Lib Secret
- [ ] Lib RHash
- [ ] Lib WebKit 2 GTK
- [ ] Lib OLM

*If needed, a complete list is available in the `flake.nix`.*

On Ubuntu, the following command should install all the required elements:

```bash
sudo apt install libjsoncpp1 libsecret-1-dev libsecret-1-0 librhash0 libwebkit2gtk-4.0-dev libolm3
```
---

In addition, the Linux build requires Rust. For macOS or Linux, execute the following command in a terminal emulator:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
For Windows, you can use the [Rust Installer](https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe).

In case you have Rust already installed, make sure to update it to latest version:

```bash
rustup update
```

#### [`devenv.nix`](devenv.nix)

A `devenv.nix` is provided in order to ease the process of setting up your dev environment. Check out the install instructions: https://devenv.sh/getting-started/

Then you can use `devenv shell` to fire up your environment.
*This can be automated thanks to: `[nix-direnv](https://github.com/nix-community/nix-direnv/)`*

Supported platforms:

- [x] Linux x86_64
- [ ] MacOS aarch_64
- [ ] MacOS x86_64
- [ ] Windows WSL

### Configure the app

In order to run the web target you must provide a default configuration file. This can be done by copying the `config.sample.json` to `config.json`.
Here is an example working with `matrix.org`:

```json
{
  "application_name": "Twake Chat",
  "application_welcome_message": "Welcome to Twake Chat!",
  "default_homeserver": "matrix.org",
  "privacy_url": "https://twake.app/en/privacy/",
  "render_html": true,
  "hide_redacted_events": true,
  "hide_unknown_events": true,
  "issue_id": "",
  "app_grid_dashboard_available": false,
  "homeserver": "https://matrix.org/",
  "platform": "localDebug",
  "default_max_upload_avatar_size_in_bytes": 1000000,
  "dev_mode": true,
  "qr_code_download_url": "https://sign-up.twake.app/download/chat",
  "enable_logs": true,
  "support_url": "https://twake.app/support",
  "cozy_external_bridge_version": "0.16.1"
}
```

### Running the code

Before running the app, please update the dependencies:

```bash
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
```

Now you can run the project:

```bash
flutter devices   # To list available run targets
```

```bash
# flutter run -d <device>, e.g:
flutter run -d chrome
```

## Build

Please use the helper script corresponding to your target in order to build:

### Web

```bash
./scripts/build-web.sh
```

### Linux

```bash
# ./scripts/build-linux.sh          ## For release purposes
./scripts/build-linux-debug.sh
```

### Android

```bash
# ./scripts/build-android-apk.sh    ## For release purposes
./scripts/build-android-debug.sh
```

## Deployment

### Web version using Docker

- Create a config file `config.json` in the root of the project with the following
  [docs](https://github.com/linagora/twake-on-matrix/blob/main/docs/configurations/config_web_app_for_public_platform.md)

- Run the image using the following command:
```
docker run -d -p <host port>:<host port> -e TWAKECHAT_LISTEN_PORT=<host port> --name <container name> -v <host path>:/usr/share/nginx/html/web/config.json linagora/twake-web:<tag>
```

- Open the browser and go to `http://localhost:<hostport>`

### Sample to run Twake Chat web client with `matrix.org`

- Create a config file `config.json` with `matrix.org`

```json
{
  "app_grid_dashboard_available": true,
  "application_name": "Twake Chat",
  "application_welcome_message": "Welcome to Twake Chat!",
  "default_homeserver": "matrix.org",
  "hide_redacted_events": false,
  "hide_unknown_events": false,
  "homeserver": "https://matrix.org/",
  "issue_id": "",
  "privacy_url": "https://twake.app/en/privacy/",
  "render_html": true
}
```

- Run the image using the following command with my port is `6868`:
```
docker run -d -p 6868:6868 -e TWAKECHAT_LISTEN_PORT=6868 --name twake-web -v /path/to/config.json:/usr/share/nginx/html/web/config.json linagora/twake-web:v2.19.7
```

- Open the browser and go to `http://localhost:6868`

# Special thanks

* <a href="https://github.com/krille-chan/fluffychat">FluffyChat</a> is the original repository of this project. A huge thanks to the upstream repository for their vital contributions, not only for this project but also for [Matrix SDK in Dart](https://github.com/famedly/matrix-dart-sdk)

* <a href="https://github.com/fabiyamada">Fabiyamada</a> is a graphics designer from Brasil and has made the fluffychat logo and the banner. Big thanks for her great designs.

* <a href="https://github.com/advocatux">Advocatux</a> has made the Spanish translation with great love and care. He always stands by my side and supports my work with great commitment.

* Thanks to MTRNord and Sorunome for developing.

* Also thanks to all translators and testers! With your help, fluffychat is now available in more than 12 languages.

* <a href="https://github.com/googlefonts/noto-emoji/">Noto Emoji Font</a> for the awesome emojis.

* <a href="https://github.com/madsrh/WoodenBeaver">WoodenBeaver</a> sound theme for the notification sound.

* The Matrix Foundation for making and maintaining the [emoji translations](https://github.com/matrix-org/matrix-doc/blob/main/data-definitions/sas-emoji.json) used for emoji verification, licensed Apache 2.0
