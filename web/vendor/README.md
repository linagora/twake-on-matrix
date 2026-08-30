# Vendored third-party assets

Served from our own origin so the app makes no cross-origin request on load,
and so the service worker can precache them.

## dotlottie

`@dotlottie/player-component@2.7.12`, copied verbatim from
`https://unpkg.com/@dotlottie/player-component@2.7.12/dist/`. Drives the splash
animation in `index.html`.

All fourteen files are the full dependency closure and must stay in the same
directory: four chunks are imported by relative name, and `chunk-TRZ6EGBZ.mjs`
additionally pulls renderer modules such as `lottie_svg-*.mjs` through dynamic
`import()`. Only the renderer the player selects is fetched at runtime; the rest
sit unused until needed.

To update, bump the version in the URL and re-copy, then resolve the closure
again rather than assuming it is unchanged:

    grep -ohE '[A-Za-z0-9_.-]+\.mjs' *.mjs | sort -u

Every name it prints must exist in this directory.
