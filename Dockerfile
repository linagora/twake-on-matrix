# Specify versions
ARG FLUTTER_VERSION=3.38.9

# Building Twake for the web.
# Builds natively for the base image's platform, so no --platform flag is
# needed; set platforms on the final stage to produce a multi-arch image.
# See .github/workflows/image.yaml for the CI build and its requirements.
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS web-builder
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

# Install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-suggests --no-install-recommends curl && \
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

# Build the web app and pre-compress the assets. SENTRY_AUTH_TOKEN is passed as
# a build secret so it never lands in an image layer.
RUN --mount=type=secret,id=sentry_auth_token,required=false \
    --mount=type=cache,target=/root/.pub-cache \
    SENTRY_AUTH_TOKEN=$(cat /run/secrets/sentry_auth_token 2>/dev/null || true) \
    ./scripts/build-web.sh && \
    find /app/build/web -type f ! -name "config.json" -exec gzip -k -f {} \;

# Final image — lean nginx:alpine with no extra packages needed
FROM nginx:alpine AS final-image
ARG TWAKECHAT_BASE_HREF
ENV TWAKECHAT_BASE_HREF=${TWAKECHAT_BASE_HREF:-/web/}
ENV TWAKECHAT_LISTEN_PORT="80"
RUN rm -rf /usr/share/nginx/html
COPY --from=web-builder /app/server/nginx.conf /etc/nginx
COPY --from=web-builder /app/build/web /usr/share/nginx/html${TWAKECHAT_BASE_HREF}
COPY ./configurations/nginx.conf.template /etc/nginx/templates/default.conf.template

# Specify the port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
