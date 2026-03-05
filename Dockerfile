# Specify versions
ARG FLUTTER_VERSION=3.38.9

# Building Twake for the web
FROM --platform=linux/arm64 ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS web-builder
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
ENV SENTRY_PROJECT=${SENTRY_PROJECT}
ENV SENTRY_ORG=${SENTRY_ORG}
ENV SENTRY_RELEASE=${SENTRY_RELEASE}
ENV SENTRY_DIST=${SENTRY_DIST}
ENV SENTRY_DSN=${SENTRY_DSN}

# Pinned yq version for reproducible builds
ARG YQ_VERSION=4.44.3

# Single apt layer: install all deps, install Rust, install yq, then clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl pkg-config libssl-dev openssh-client && \
    rm -rf /var/lib/apt/lists/* && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_arm64" \
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

# Pre-compress all web assets at build time (avoids re-compressing on every container start)
RUN gzip -k -r -f /app/build/web/

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
