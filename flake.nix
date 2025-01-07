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
        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        androidComposition = androidEnv.composeAndroidPackages {
          cmdLineToolsVersion = "8.0"; # emulator related: newer versions are not only compatible with avdmanager
          platformToolsVersion = "34.0.4";
          buildToolsVersions = [ "30.0.3" "33.0.2" "34.0.0" ];
          platformVersions = [ "28" "31" "32" "33" "34" ];
          abiVersions = [ "x86_64" ]; # emulator related: on an ARM machine, replace "x86_64" with
          # either "armeabi-v7a" or "arm64-v8a", depending on the architecture of your workstation.
          includeNDK = true;
          ndkVersions = ["23.1.7779620"];
          cmakeVersions = [ "3.18.1" ];          
          includeSystemImages = true; # emulator related: system images are needed for the emulator.
          systemImageTypes = [ "google_apis" "google_apis_playstore" ];
          includeEmulator = true; # emulator related: if it should be enabled or not
          useGoogleAPIs = true;
          extraLicenses = [
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "android-sdk-license"
            "android-sdk-preview-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"            ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = with pkgs; mkShell rec {
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          CHROME_EXECUTABLE = "google-chrome-stable";
          JAVA_HOME = jdk17.home;
          FLUTTER_ROOT = flutter324;
          DART_ROOT = "${flutter324}/bin/cache/dart-sdk";
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/33.0.2/aapt2";
          QT_QPA_PLATFORM = "wayland;xcb"; # emulator related: try using wayland, otherwise fall back to X
          # NB: due to the emulator's bundled qt version, it currently does not start with QT_QPA_PLATFORM="wayland".
          # Maybe one day this will be supported.
          buildInputs = [
            androidSdk
            cmake
            flutter324
            gradle_7
            jdk17
            google-chrome
            chromedriver

            # Linux Build
            fribidi.dev
            jsoncpp.dev
            libass.dev
            libdrm.dev
            libepoxy.dev
            libgbm
            libsecret.dev
            libsysprof-capture
            mpv-unwrapped.dev
            olm
            pcre2.dev
            pkg-config
            rhash
            webkitgtk_4_0.dev
            xorg.libXdmcp.dev
          ];
          # emulator related: vulkan-loader and libGL shared libs are necessary for hardware decoding
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [vulkan-loader libGL]}";
          CMAKE_PREFIX_PATH = "${pkgs.lib.makeLibraryPath [libsecret.dev gtk3.dev]}";
          # Globally installed packages, which are installed through `dart pub global activate package_name`,
          # are located in the `$PUB_CACHE/bin` directory.
          shellHook = ''
            if [ -z "$PUB_CACHE" ]; then
              export PATH="$PATH:$HOME/.pub-cache/bin"
            else
              export PATH="$PATH:$PUB_CACHE/bin"
            fi
          '';
        };
      }
    );
}
