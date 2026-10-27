# Specify versions
# FLUTTER_VERSION must match .fvmrc and FLUTTER_VERSION in .github/workflows/tests.yaml.
# cirruslabs/flutter has no 3.47.x image, so the stage starts from the newest image
# (FLUTTER_IMAGE_VERSION) and moves its Flutter checkout to FLUTTER_VERSION.
ARG FLUTTER_IMAGE_VERSION=3.44.0
ARG FLUTTER_VERSION=3.47.5
# Pins both nginx stages and the source the brotli module is compiled against.
ARG NGINX_VERSION=1.31.8

# Building Twake for the web.
# The web output is platform-independent: this stage runs once, on the build
# host's platform, and only the nginx stages are built per target platform.
# See .github/workflows/image.yaml for the CI build and its requirements.
FROM --platform=$BUILDPLATFORM ghcr.io/cirruslabs/flutter:${FLUTTER_IMAGE_VERSION} AS web-builder
ARG FLUTTER_VERSION
ARG TWAKECHAT_BASE_HREF="/web/"
# Sentry values are injected from build args; only SENTRY_PROJECT and SENTRY_ORG
# are required. The auth token is passed as a build secret, not an arg.
ARG SENTRY_PROJECT=""
ARG SENTRY_ORG=""
ARG SENTRY_RELEASE=""
ARG SENTRY_DIST=""
ARG SENTRY_DSN=""
ARG SENTRY_ENVIRONMENT=""
ENV SENTRY_PROJECT=${SENTRY_PROJECT} \
    SENTRY_ORG=${SENTRY_ORG} \
    SENTRY_RELEASE=${SENTRY_RELEASE} \
    SENTRY_DIST=${SENTRY_DIST} \
    SENTRY_DSN=${SENTRY_DSN} \
    SENTRY_ENVIRONMENT=${SENTRY_ENVIRONMENT}

# The base image ships a shallow Flutter checkout; move it to FLUTTER_VERSION and
# download the matching Dart SDK and web artifacts.
RUN git -C "$FLUTTER_ROOT" fetch --depth 1 origin tag "${FLUTTER_VERSION}" && \
    git -C "$FLUTTER_ROOT" checkout "${FLUTTER_VERSION}" && \
    flutter precache --web && \
    flutter --version

# Install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-suggests --no-install-recommends curl brotli && \
    rm -rf /var/lib/apt/lists/*

# Rust toolchain, architecture-matched yq, and the Sentry CLI
ARG YQ_VERSION=4.44.3
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(dpkg --print-architecture)" \
      -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    curl -sL https://sentry.io/get-cli/ | sh
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# Heavy, rarely-changing step: vodozemac Rust toolchain and wasm codegen.
# Needs only pubspec.yaml and the prepare script, so source edits don't
# invalidate this layer; cargo caches are mounted to speed up rebuilds.
COPY pubspec.yaml pubspec.lock ./
COPY scripts/prepare-web.sh scripts/prepare-web.sh
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    --mount=type=cache,target=/root/.cargo/vodozemac-target \
    mkdir -p web && \
    CARGO_TARGET_DIR=/root/.cargo/vodozemac-target ./scripts/prepare-web.sh

# Remaining sources, filtered by .dockerignore
COPY . .

# Cache pub packages across builds; build-web.sh calls configure-sentry.sh internally.
# SENTRY_AUTH_TOKEN passed as a Docker build secret to avoid leaking it in image layers
# or `docker history` output.
RUN --mount=type=secret,id=sentry_auth_token,required=false \
    --mount=type=cache,target=/root/.pub-cache \
    SENTRY_AUTH_TOKEN=$(cat /run/secrets/sentry_auth_token 2>/dev/null || true) \
    ./scripts/build-web.sh

# Pre-compress all web assets at build time (avoids re-compressing on every container start).
# Both encodings are produced: nginx picks .br or .gz from Accept-Encoding, and falls back to
# the plain file. The brotli pass skips the .gz twins the first one just created.
# brotli -q 11 costs about 6 minutes sequentially, most of it on main.dart.js
# alone, so the pass is parallelised.
RUN find /app/build/web -type f ! -name "config.json" -exec gzip -k -f {} \; && \
    find /app/build/web -type f ! -name "config.json" ! -name "*.gz" -print0 \
      | xargs -0 -P 4 -n 1 brotli -k -f -q 11

# ngx_brotli is not packaged for the nginx image: Alpine ships a module built against its
# own nginx, which the official binary refuses. Build it here against the exact version the
# final stage runs, so a base image bump rebuilds a matching module instead of silently
# loading a stale one. Only the static module is kept: assets are pre-compressed above, so
# on-the-fly compression is never needed.
FROM nginx:${NGINX_VERSION}-alpine AS brotli-builder
# Both inputs compiled into the module are pinned, so two identical builds cannot
# produce different module code: the nginx source by version and digest, and
# ngx_brotli by commit rather than a branch. Signature checking was considered
# and dropped, nginx having rotated its release key without updating the bundle
# it publishes at /keys/, which would break the build at the next rotation.
#
# The base image tag is pinned to NGINX_VERSION, so upstream releases no longer
# change it: a bump is a pull request updating NGINX_VERSION and NGINX_SHA256.
# The check below stays as a guard, since a module compiled against the wrong
# version would be refused at load time.
ARG NGINX_VERSION
ARG NGINX_SHA256=0652b760b3b772d2ec17b47c2fc15d9a95e6fe35cd5b877eadc1a62d9bc75af1
ARG NGX_BROTLI_COMMIT=a71f9312c2deb28875acc7bacfdd5695a111aa53
RUN set -eux; \
    image_version="$(nginx -v 2>&1 | sed 's|.*/||')"; \
    if [ "$image_version" != "$NGINX_VERSION" ]; then \
      echo "base image runs nginx $image_version but NGINX_VERSION pins $NGINX_VERSION;" >&2; \
      echo "update NGINX_VERSION and NGINX_SHA256 in this Dockerfile" >&2; \
      exit 1; \
    fi; \
    apk add --no-cache build-base pcre-dev zlib-dev openssl-dev linux-headers curl git \
                       brotli-dev brotli-static; \
    curl -fsSL -o /tmp/nginx.tar.gz "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"; \
    echo "${NGINX_SHA256}  /tmp/nginx.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/nginx.tar.gz -C /tmp; \
    git clone https://github.com/google/ngx_brotli.git /tmp/ngx_brotli; \
    git -C /tmp/ngx_brotli checkout "$NGX_BROTLI_COMMIT"; \
    git -C /tmp/ngx_brotli submodule update --init --recursive; \
    cd "/tmp/nginx-${NGINX_VERSION}"; \
    ./configure --with-compat --add-dynamic-module=/tmp/ngx_brotli; \
    make modules; \
    cp objs/ngx_http_brotli_static_module.so /tmp/

# Final image — lean nginx:alpine with no extra packages needed
FROM nginx:${NGINX_VERSION}-alpine AS final-image
ARG TWAKECHAT_BASE_HREF
ENV TWAKECHAT_BASE_HREF=${TWAKECHAT_BASE_HREF:-/web/}
ENV TWAKECHAT_LISTEN_PORT="80"
RUN rm -rf /usr/share/nginx/html
COPY --from=brotli-builder /tmp/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
COPY --from=web-builder /app/server/nginx.conf /etc/nginx
COPY --from=web-builder /app/build/web /usr/share/nginx/html${TWAKECHAT_BASE_HREF}
COPY ./configurations/nginx.conf.template /etc/nginx/templates/default.conf.template

# Specify the port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
