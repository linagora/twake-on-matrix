{
  pkgs,
  lib,
  config,
  ...
}:

{
  packages = [
    pkgs.git

    # pkgs.perl
    pkgs.ungoogled-chromium
    pkgs.yq-go
  ];

  env = {
    CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}/bin/chromium";
    TWAKECHAT_BASE_HREF = "/";
  };

  # ─── Flutter & Dart Environment ──────────────────────────────────────────
  android = {
    enable = true;

    flutter = {
      enable = true;
      package = pkgs.flutter338;
    };

    platforms.version = [
      # "31"
      # "32"
      # "33"
      # "34"
      # "35"
      "36"
    ];

    buildTools.version = [
      "28.0.3"
      # "34.0.0"
    ];

    ndk.enable = true;
    googleAPIs.enable = true;

    # extraLicenses = [
    #   "android-sdk-preview-license"
    #   "android-googletv-license"
    #   "android-sdk-arm-dbt-license"
    #   "google-gdk-license"
    #   "intel-android-extra-license"
    #   "intel-android-sysimage-license"
    #   "mips-android-sysimage-license"
    #   "android-googlexr-license"
    # ];
    # extraLicenses = [
    #   "android-googletv-license"
    #   "android-sdk-arm-dbt-license"
    #   "android-sdk-license"
    #   "android-sdk-preview-license"
    #   "google-gdk-license"
    #   "intel-android-extra-license"
    #   "intel-android-sysimage-license"
    #   "mips-android-sysimage-license"
    # ];
  };

  languages.dart.enable = true;

  # ─── Rust/Web Build Environment ──────────────────────────────────────────
  languages.rust = {
    enable = true;
    channel = "nightly";
    components = [
      "rustc"
      "cargo"
      "rust-src"
    ];
    targets = [ "wasm32-unknown-unknown" ];
  };

  # ─── Files ───────────────────────────────────────────────────────────────
  files."config.json" = {
    json = {
      application_name = "Twake Chat";
      application_welcome_message = "Welcome to Twake Chat!";
      homeserver = "https://matrix.twake.localhost/";
      default_homeserver = "matrix.twake.localhost";
      twake_workplace_homeserver = "https://tom.twake.localhost/";
    };

    copyMode = "copy";
  };

  # ─── Scripts (Atomic Operations) ─────────────────────────────────────────
  scripts = {
    # 1. Shared Setup
    "flutter-setup" = {
      description = "Cleans Flutter env, fetches dependencies, and generates build files";
      exec = ''
        set -e
        flutter clean
        flutter pub get
        # dart run build_runner build --delete-conflicting-outputs
      '';
    };

    # 2. Sentry Configuration
    "sentry-configure" = {
      description = "Injects Sentry config from environment variables into pubspec.yaml";
      exec = ''
        set -eu

        _pubspec_ver=$(grep "^version:" pubspec.yaml | tr -d ' ' | cut -d: -f2)
        SENTRY_RELEASE="''${SENTRY_RELEASE:-$(echo "''${_pubspec_ver}" | cut -d'+' -f1)}"
        SENTRY_DIST="''${SENTRY_DIST:-$(echo "''${_pubspec_ver}" | cut -s -d'+' -f2)}"
        SENTRY_DSN="''${SENTRY_DSN:-}"
        SENTRY_ENVIRONMENT="''${SENTRY_ENVIRONMENT:-}"

        _base_href="''${TWAKECHAT_BASE_HREF:-/}"
        SENTRY_URL_PREFIX="~''${_base_href}"

        perl -pi -e "s|^  project:.*|  project: ''${SENTRY_PROJECT}|" pubspec.yaml
        perl -pi -e "s|^  org:.*|  org: ''${SENTRY_ORG}|" pubspec.yaml
        perl -pi -e "s|^  release:.*|  release: ''${SENTRY_RELEASE}|" pubspec.yaml
        perl -pi -e "s|^  dist:.*|  dist: \"''${SENTRY_DIST}\"|" pubspec.yaml
        perl -pi -e "s|^  url_prefix:.*|  url_prefix: ''${SENTRY_URL_PREFIX}|" pubspec.yaml

        if [ -n "$SENTRY_DSN" ]; then
          perl -pi -e 's|"sentry_dsn":.*|"sentry_dsn": "''$ENV{SENTRY_DSN}",|' config.sample.json
        fi

        if [ -n "$SENTRY_ENVIRONMENT" ]; then
          perl -pi -e 's|"sentry_environment":.*|"sentry_environment": "''$ENV{SENTRY_ENVIRONMENT}"|' config.sample.json
        fi
      '';
    };

    "sentry-run" = {
      description = "Runs the Sentry Dart plugin";
      exec = ''
        if [ -n "''${SENTRY_ORG:-}" ] && [ -n "''${SENTRY_PROJECT:-}" ] && [ -n "''${SENTRY_AUTH_TOKEN:-}" ]; then
          echo "Sentry configuration found. Running sentry_dart_plugin..."
          dart run sentry_dart_plugin
        else
          echo "Skipping sentry_dart_plugin: Missing SENTRY_ORG, SENTRY_PROJECT, or SENTRY_AUTH_TOKEN."
        fi
      '';
    };

    # 3. Web Specific
    "web-prepare-vodozemac" = {
      description = "Builds the Rust WebAssembly bridge (Vodozemac)";
      exec = ''
        set -e
        files=(web/pkg/vodozemac*)
        if [ -e "''${files[0]}" ]; then
            echo "Vodozemac Already Built!"
            exit 0
        else
            echo "Building vodozemac..."
        fi

        rm -rf .vodozemac
        version=$(yq -r ".dependencies.flutter_vodozemac" < pubspec.yaml | sed 's/[^0-9.]//g')
        git clone https://github.com/famedly/dart-vodozemac.git -b "$version" .vodozemac

        cargo install flutter_rust_bridge_codegen --force

        cd .vodozemac
        flutter_rust_bridge_codegen build-web --dart-root dart --rust-root "$(cd rust && pwd)" --release --verbose
        cd ..

        rm -rf ./web/pkg && mv .vodozemac/dart/web/pkg ./web/ && rm -rf .vodozemac
      '';
    };

    "web-build-release" = {
      description = "Builds the Flutter web release version";
      exec = ''
        set -e
        flutter build web --release --verbose --source-maps --base-href="$TWAKECHAT_BASE_HREF"
      '';
    };

    # 4. Android Specific
    "android-build-debug" = {
      description = "Builds Android Debug APK";
      exec = ''
        set -e
        flutter build apk --debug
      '';
    };

    "android-build-release" = {
      description = "Builds Android Release APK with Sentry obfuscation";
      exec = ''
        set -e
        flutter build apk --dart-define=SENTRY_DSN="''${SENTRY_DSN:-}" \
          --dart-define=SENTRY_ENVIRONMENT="''${SENTRY_ENVIRONMENT:-}" \
          --release --obfuscate \
          --split-debug-info=build/app/outputs/symbols \
          --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json

        mkdir -p build/android
        cp build/app/outputs/apk/release/app-release.apk build/android/
      '';
    };
  };

  # ─── Web Serving ─────────────────────────────────────────────────────────
  # 1. Automate DNS Resolution (/etc/hosts)
  hosts = {
    "chat.twake.localhost" = "127.0.0.1";
  };

  # 2. Automate TLS Certificate Generation (mkcert)
  certificates = [
    "chat.twake.localhost"
  ];
  certFile = "twake-cert.pem";
  keyFile = "twake-key.pem";

  services = {
    caddy = {
      enable = true;
      virtualHosts."chat.twake.localhost" = {
        extraConfig = ''
          # This line STOPS Caddy from using its own CA
          tls ${config.env.DEVENV_STATE}/mkcert/twake-cert.pem ${config.env.DEVENV_STATE}/mkcert/twake-key.pem

          root * ${config.env.DEVENV_ROOT}/build/web
          file_server
          try_files {path} {path}/ /index.html
        '';
      };
    };
  };

  # ─── Tasks (User-Facing Workflows) ───────────────────────────────────────
  tasks = {
    # Setup Tasks
    "setup:flutter" = {
      description = "Cleans Flutter env, fetches packages, and runs build_runner";
      exec = "flutter-setup";
    };

    "setup:web" = {
      description = "Builds WebAssembly bridge dependencies";
      exec = "web-prepare-vodozemac";
      after = [ "setup:flutter" ];
    };

    # Build Tasks
    "build:web" = {
      description = "Configures Sentry and builds Web Release";
      exec = "sentry-configure && web-build-release && sentry-run";
      after = [ "setup:web" ];
    };

    "build:android:debug" = {
      description = "Builds Android Debug APK";
      exec = "android-build-debug";
      after = [ "setup:flutter" ];
    };

    "build:android:release" = {
      description = "Configures Sentry and builds Android Release APK";
      exec = "sentry-configure && android-build-release && sentry-run";
      after = [ "setup:flutter" ];
    };
  };

  # ─── Shell Greeting ──────────────────────────────────────────────────────
  enterShell = ''
    echo "─── TwakeChat Devenv Commands ─────────────────────────────────────"
    echo ""
    echo "Run setup targets first:"
    echo "  devenv tasks run setup:flutter"
    echo "  devenv tasks run setup:web"
    echo ""
    echo "Build Web:"
    echo "  devenv tasks run build:web"
    echo ""
    echo "Build Android:"
    echo "  devenv tasks run build:android:debug"
    echo "  devenv tasks run build:android:release"
    echo ""
  '';
}
