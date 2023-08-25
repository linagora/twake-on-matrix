# Specify versions
ARG FLUTTER_VERSION=3.10.6
ARG OLM_VERSION=3.2.15

# Building libolm
FROM nixos/nix AS olm-builder
ARG OLM_VERSION
RUN nix build -v --extra-experimental-features flakes --extra-experimental-features nix-command gitlab:matrix-org/olm/${OLM_VERSION}?host=gitlab.matrix.org\#javascript

# Building Twake web files
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} as web-builder
COPY . /app
WORKDIR /app
RUN apt update && \
    apt install openssh-client -y && \
    rm -rf assets/js/* && \
    mkdir ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts
COPY --from=olm-builder /result/javascript assets/js/package
RUN --mount=type=ssh,required=true ./scripts/build-web.sh

# Final image
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html
COPY --from=web-builder /app/build/web /usr/share/nginx/html/web/
