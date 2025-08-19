{ pkgs, ... }:

{
  android = {
    enable = true;

    flutter = {
      enable = true;
      package = pkgs.flutter327;
    };

    platforms.version = [
      "31"
      "32"
      "33"
      "34"
      "35"
    ];

    buildTools.version = [
      "34.0.0"
    ];

    ndk.enable = true;
    googleAPIs.enable = true;

    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

  languages.dart.enable = true;

  enterShell = ''
    if [ -z "$PUB_CACHE" ]; then
      export PATH="$PATH:$HOME/.pub-cache/bin"
    else
      export PATH="$PATH:$PUB_CACHE/bin"
    fi
  '';
}
