# Specify versions
ARG FLUTTER_VERSION=3.32.8

# Build stage for vodozemac (Rust WebAssembly)
FROM rust:1.83-bookworm AS vodozemac-builder
ARG FLUTTER_VERSION
WORKDIR /app
# Install build dependencies, ensuring minimal image size
RUN apt-get update && apt-get install -y --no-install-recommends git curl ca-certificates && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Install Flutter to ensure dependency tools are available (needed for pubspec.yaml parsing)
RUN curl --proto '=https' --tlsv1.2 -sSf https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz \
    | tar -xJvf - --strip-components=1 -C /usr/local/
ENV PATH="/usr/local/bin:${PATH}"
# Add /usr/local to git's safe directory list to avoid dubious ownership errors
RUN git config --global --add safe.directory /usr/local
# Install and set nightly toolchain as default, then add rust-src for it
RUN rustup toolchain install nightly && \
    rustup default nightly && \
    rustup component add rust-src --toolchain nightly && \
    # Clean up rustup cache directories immediately to free up space
    rm -rf "$(rustup show home)"/tmp && \
    rm -rf "$(rustup show home)"/download
# Copy only necessary files for vodozemac build
COPY pubspec.yaml pubspec.yaml
COPY scripts/prepare-web.sh scripts/prepare-web.sh
# Execute prepare-web.sh to build vodozemac WASM
RUN ./scripts/prepare-web.sh

# Building Twake for the web
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS web-builder
ARG TWAKECHAT_BASE_HREF="/web/"

COPY . /app
WORKDIR /app
RUN DEBIAN_FRONTEND=noninteractive apt update && \
    apt install -y openssh-client && \
    # The ssh-keyscan and openssh-client might be needed for flutter pub get or other operations
    # if it involves private git repos from pubspec.yaml, as indicated by user's feedback.
    ssh-keyscan github.com >> ~/.ssh/known_hosts

# Copy vodozemac WASM artifacts from the vodozemac-builder stage
COPY --from=vodozemac-builder /app/web/pkg /app/web/pkg
RUN --mount=type=ssh,required=true ./scripts/build-web.sh

# Final image
FROM nginx:alpine AS final-image
ARG TWAKECHAT_BASE_HREF
ENV TWAKECHAT_BASE_HREF=${TWAKECHAT_BASE_HREF:-/web/}
ENV TWAKECHAT_LISTEN_PORT="80"
RUN apk add gzip
RUN rm -rf /usr/share/nginx/html
COPY --from=web-builder /app/server/nginx.conf /etc/nginx
COPY --from=web-builder /app/build/web /usr/share/nginx/html${TWAKECHAT_BASE_HREF}
COPY ./configurations/nginx.conf.template /etc/nginx/templates/default.conf.template

# Specify the port
EXPOSE 80

# Before stating NGinx, re-zip all the content to ensure customizations are propagated
CMD gzip -k -r -f /usr/share/nginx/html/ && nginx -g 'daemon off;'
