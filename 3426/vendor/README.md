# Vendored third-party assets

Served from our own origin so the app makes no cross-origin request on load,
and so the service worker can precache them.

Nothing here is committed by hand. `scripts/fetch-web-vendor.sh` downloads the
published packages at a pinned version, checks each tarball against the
integrity hash the registry publishes, and extracts the modules. Run it once
before serving `web/` locally; `scripts/build-web.sh` calls it on every build.

## dotlottie

`@dotlottie/player-component`, drives the splash animation in `index.html`.

The whole `dist/` is taken rather than the files that appear to be imported:
`chunk-TRZ6EGBZ.mjs` reaches its renderers through dynamic `import()`, so
selecting modules by reading import statements misses them. Six of the fifteen
load at runtime, the rest stay unused until the player needs them.

To update, change `DOTLOTTIE_VERSION` and `DOTLOTTIE_INTEGRITY` in the script.
The integrity value comes from:

    curl -s https://registry.npmjs.org/@dotlottie/player-component/<version> \
      | python3 -c 'import json,sys; print(json.load(sys.stdin)["dist"]["integrity"])'
