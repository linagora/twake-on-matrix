# Specify versions
ARG FLUTTER_VERSION=3.38.9

# Building Twake for the web
FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS web-builder
ARG TWAKECHAT_BASE_HREF="/web/"
# Sentry: all values passed from outside — nothing is hardcoded here.
# Usage: docker build \
#   --secret id=sentry_auth_token,src=<token-file> \
#   --build-arg SENTRY_PROJECT=twake-chat \
#   --build-arg SENTRY_ORG=datcorp \
#   --build-arg SENTRY_RELEASE=2.19.7 \
#   --build-arg SENTRY_DIST=2330 \
#   ...
ARG SENTRY_PROJECT=""
ARG SENTRY_ORG=""
ARG SENTRY_RELEASE=""
ARG SENTRY_DIST=""
ARG SENTRY_DSN=""
ARG SENTRY_ENVIRONMENT=""
ENV SENTRY_PROJECT=${SENTRY_PROJECT}
ENV SENTRY_ORG=${SENTRY_ORG}
ENV SENTRY_RELEASE=${SENTRY_RELEASE}
ENV SENTRY_DIST=${SENTRY_DIST}
ENV SENTRY_DSN=${SENTRY_DSN}
ENV SENTRY_ENVIRONMENT=${SENTRY_ENVIRONMENT}

# Pinned yq version for reproducible builds
ARG YQ_VERSION=4.44.3

# Single apt layer: install all deps, install Rust, install yq, then clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl pkg-config libssl-dev openssh-client brotli && \
    rm -rf /var/lib/apt/lists/* && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
      -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    curl -sL https://sentry.io/get-cli/ | sh
ENV PATH="/root/.cargo/bin:${PATH}"

COPY . /app
WORKDIR /app

RUN rm -rf assets/js/* && \
    mkdir -p assets/js/package && \
    rm -rf fastlane && \
    mkdir -p fastlane && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

# Cache cargo registry, git deps, nightly toolchain components, and compiled Rust artifacts.
RUN --mount=type=ssh,required=true \
    --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    --mount=type=cache,target=/root/.cargo/vodozemac-target \
    CARGO_TARGET_DIR=/root/.cargo/vodozemac-target \
    ./scripts/prepare-web.sh

# Cache pub packages across builds; build-web.sh calls configure-sentry.sh internally.
# SENTRY_AUTH_TOKEN passed as a Docker build secret to avoid leaking it in image layers
# or `docker history` output.
RUN --mount=type=ssh,required=true \
    --mount=type=secret,id=sentry_auth_token,required=false \
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
FROM nginx:alpine AS brotli-builder
# Both inputs compiled into the module are pinned, so two identical builds cannot
# produce different module code: the nginx source by version and digest, and
# ngx_brotli by commit rather than a branch. Signature checking was considered
# and dropped, nginx having rotated its release key without updating the bundle
# it publishes at /keys/, which would break the build at the next rotation.
#
# NGINX_VERSION must match the base image. A base image bump therefore fails the
# build until both values below are updated, which is deliberate: it turns an
# unreviewed upstream change into a review point, and a module compiled against
# the wrong version would be refused at load time anyway.
ARG NGINX_VERSION=1.29.4
ARG NGINX_SHA256=5a7d37eee505866fbab5810fa9f78247d6d5d9157a595c4e7a72043141ddab25
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
FROM nginx:alpine AS final-image
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
