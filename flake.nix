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
          ## Details about default values: https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/mobile/androidenv/compose-android-packages.nix
          #
          buildToolsVersions = [ "30.0.3" "35.0.0" ];
          ## Emulators seem to be buggy for the momment
          # includeSystemImages = true;
          # systemImageTypes = [ "google_apis" "google_apis_playstore" ];
          # abiVersions = [ "x86_64" ];
          # includeEmulator = true;
          platformVersions = [ "31" "32" "33" "34" ];
          cmakeVersions = [ "3.18.1" ];
          includeNDK = true;
          ndkVersion = "23.1.7779620";
          useGoogleAPIs = true;
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
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = with pkgs; mkShell rec {
          FLUTTER_ROOT = flutter324;
          DART_ROOT = "${flutter324}/bin/cache/dart-sdk";

          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";

          JAVA_HOME = jdk17.home;
          JAVA_8_HOME = jdk8.home;
          JAVA_17_HOME = jdk17.home;
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/35.0.0/aapt2";

          # QT_QPA_PLATFORM = "wayland;xcb";  # emulator related: try using wayland, otherwise fall back to X
                                              # NB: due to the emulator's bundled qt version, it currently does not start with QT_QPA_PLATFORM="wayland".
                                              # Maybe one day this will be supported.

          CHROME_EXECUTABLE = "google-chrome-stable";

          buildInputs = [
            ## General needs
            flutter324

            ## Chrome target
            yq
            google-chrome

            ## Android target
            androidSdk
            jdk17
            jdk8  # for gradle sake...
            ruby

            ## Linux target
            alsa-lib.dev
            cargo
            clang
            cmake
            ffmpeg-headless.dev
            fribidi.dev
            gtk3.dev
            jsoncpp.dev
            lcms.dev
            lerc.dev
            libarchive.dev
            libass.dev
            libbluray.out
            libcaca.dev
            libdatrie.dev
            libdovi
            libdrm.dev
            libdvdnav
            libdvdread
            libepoxy.dev
            libgbm
            libgcrypt.dev
            libgpg-error.dev
            libplacebo
            libpulseaudio.dev
            libsecret.dev
            libselinux.dev
            libsepol.dev
            libsysprof-capture
            libthai.dev
            libuchardet.dev
            libunwind.dev
            libva.dev
            libvdpau.dev
            libxkbcommon.dev
            libxml2.dev
            lua
            mpv-unwrapped.dev
            mujs
            ninja
            nv-codec-headers-11
            olm
            openal
            openssl.dev
            pcre2.dev
            pipewire.dev
            pkg-config
            rhash
            rubberband
            rustc
            shaderc.dev
            util-linux.dev
            vulkan-loader.dev
            xorg.libXdmcp.dev
            xorg.libXpresent
            xorg.libXScrnSaver
            xorg.libXtst
            zimg.dev
          ];

          # emulator related: vulkan-loader and libGL shared libs are necessary for hardware decoding
          # LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [ vulkan-loader libGL ]}";
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [ libdrm libgbm ]}";
          # CMAKE_PREFIX_PATH = "${pkgs.lib.makeLibraryPath [ fribidi ]}";

          # Globally installed packages, which are installed through `dart pub global activate package_name`,
          # are located in the `$PUB_CACHE/bin` directory.
          shellHook = ''
            if [ -z "$PUB_CACHE" ]; then
              export PATH="$PATH:$HOME/.pub-cache/bin"
            else
              export PATH="$PATH:$PUB_CACHE/bin"
            fi

            ## direnv (sometimes) stays stuck...
            # flutter doctor -v

            ## TODO: find flag to set `-I fribidi`
            echo
            echo
            echo "In case of fribidi include issue, consider using:"
            echo "sed -i 's#<fribidi.h>#<fribidi/fribidi.h>#' ./linux/flutter/ephemeral/.plugin_symlinks/handy_window/linux/libhandy/src/src/hdy-bidi.c"

            ## Just to please Gradle with a JDK8
            echo
            echo
            echo "Please Make Sure That: '$HOME/.gradle/gradle.properties' contains:"
            echo "org.gradle.java.installations.paths=$JAVA_8_HOME,$JAVA_17_HOME"
            echo
            echo
          '';
        };
      }
    );
}
