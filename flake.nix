{
  description = "Flutter environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.permittedInsecurePackages = [
            "olm-3.2.16"
          ];
        };
        # androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        # androidComposition = androidEnv.composeAndroidPackages {
        #   ## Details about default values: https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/mobile/androidenv/compose-android-packages.nix
        #   #
        #   buildToolsVersions = [ "30.0.3" ];
        #   platformVersions = [ "31" "32" "33" "34" ];
        #   cmakeVersions = [ "3.18.1" ];
        #   includeNDK = true;
        #   ndkVersion = "23.1.7779620";
        #   useGoogleAPIs = true;
        #   extraLicenses = [
        #     "android-googletv-license"
        #     "android-sdk-arm-dbt-license"
        #     "android-sdk-license"
        #     "android-sdk-preview-license"
        #     "google-gdk-license"
        #     "intel-android-extra-license"
        #     "intel-android-sysimage-license"
        #     "mips-android-sysimage-license"
        #   ];
        # };
        # androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = with pkgs; mkShell rec {
          # ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          # ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          CHROME_EXECUTABLE = "google-chrome-stable";
          # JAVA_HOME = jdk17.home;
          FLUTTER_ROOT = flutter324;
          DART_ROOT = "${flutter324}/bin/cache/dart-sdk";
          # GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/30.0.3/aapt2";
          QT_QPA_PLATFORM = "wayland;xcb"; # emulator related: try using wayland, otherwise fall back to X
          # NB: due to the emulator's bundled qt version, it currently does not start with QT_QPA_PLATFORM="wayland".
          # Maybe one day this will be supported.
          buildInputs = [
            ## General needs
            flutter324

            ## Chrome target
            yq
            google-chrome
            chromedriver

            ## Android target
            # androidSdk
            # gradle
            # jdk17
            # android-tools
            # android-udev-rules

            ## Linux target
            # fribidi.dev
            # jsoncpp.dev
            # libass.dev
            # libdrm.dev
            # libepoxy.dev
            # libgbm
            # libsecret.dev
            # libsysprof-capture
            # mpv-unwrapped.dev
            # olm
            # pcre2.dev
            # pkg-config
            # rhash
            # webkitgtk_4_0.dev
            # xorg.libXdmcp.dev
          ];
          # emulator related: vulkan-loader and libGL shared libs are necessary for hardware decoding
          # LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [vulkan-loader libGL]}";
          # CMAKE_PREFIX_PATH = "${pkgs.lib.makeLibraryPath [libsecret.dev gtk3.dev]}";
          # Globally installed packages, which are installed through `dart pub global activate package_name`,
          # are located in the `$PUB_CACHE/bin` directory.
          shellHook = ''
            if [ -z "$PUB_CACHE" ]; then
              export PATH="$PATH:$HOME/.pub-cache/bin"
            else
              export PATH="$PATH:$PUB_CACHE/bin"
            fi

            flutter doctor -v
          '';
        };
      }
    );
}
