# Vendored third-party assets

Served from our own origin so the app makes no cross-origin request on load,
and so the service worker can precache them.

## dotlottie

`@dotlottie/player-component@2.7.12`, files copied verbatim from
`https://unpkg.com/@dotlottie/player-component@2.7.12/dist/`. Drives the splash
animation in `index.html`. The chunks are imported by relative name, so all five
files must stay in the same directory.

To update, bump the version in the URL and re-copy every file, then check that
`dotlottie-player.mjs` references no chunk that was not copied.
