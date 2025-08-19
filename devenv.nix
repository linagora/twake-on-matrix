{
  pkgs,
  lib,
  config,
  ...
}:

let
  server_port = 8000;
in
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

  packages = [
    pkgs.chromium
  ];

  env = {
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
    TWAKECHAT_BASE_HREF = "/";
  };

  scripts._tc-build-olm-js = {
    exec = ''
      test -f ./assets/js/package/olm.js && exit 0;

      nix_store_path=$(nix build --no-link --print-out-paths gitlab:matrix-org/olm/3.2.16?host=gitlab.matrix.org#javascript)
      find "$nix_store_path/javascript" -type f \( -name "*.js" -o -name "*.wasm" \) -exec cp -v --no-preserve=all {} assets/js/package/ \;
    '';
  };

  scripts._tc-build-web = {
    exec = ''
      ./scripts/build-web.sh
    '';
  };

  scripts._tc-build-android-debug = {
    exec = ''
      ./scripts/build-android-debug.sh
    '';
  };

  # scripts._tc-build-android-release = {
  #   exec = ''
  #     ./scripts/prepare-android-release.sh
  #     ./scripts/build-android-apk
  #   '';
  # };

  enterShell = ''
    if [ -z "$PUB_CACHE" ]; then
      export PATH="$PATH:$HOME/.pub-cache/bin"
    else
      export PATH="$PATH:$PUB_CACHE/bin"
    fi

    echo
    echo 🦾 Helper scripts you can run to make your development richer:
    echo 🦾
    ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF | ${pkgs.util-linuxMinimal}/bin/column -t | ${pkgs.gnused}/bin/sed -e 's|^|🦾 |' -e 's|••| |g'
    ${lib.generators.toKeyValue { } (lib.mapAttrs (name: value: value.description) config.scripts)}
    EOF
    echo
    echo You are now ready to go!
    echo
    echo To start working on the web, please build olm.js first: _tc-build-olm-js
    echo Then run flutter as usual - e.g. flutter run -d chrome
    echo
    echo ---
    echo
    echo You can also start a local NGINX server like so:
    echo 1. _tc-build-web
    echo 2. devenv up
    echo
  '';

  tasks."web:build" = {
    exec = "_tc-build-web";
    before = [ "devenv:processes:nginx" ];
    execIfModified = [
      "web"
      "lib"
    ];
  };

  tasks."web:update-config" = {
    exec = "cat config.sample.json > build/web/config.json";
    before = [ "devenv:processes:nginx" ];
    after = [ "web:build" ];
    execIfModified = [
      "config.sample.json"
    ];
  };

  services.nginx = {
    enable = true;
    httpConfig = ''
      server {
        listen ${toString server_port};
        root ${config.env.DEVENV_ROOT}/build/web;
      }
    '';
  };
}
