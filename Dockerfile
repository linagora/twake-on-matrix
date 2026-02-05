# Specify versions
ARG FLUTTER_VERSION=3.38.9

# Building Twake for the web
FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS web-builder
ARG TWAKECHAT_BASE_HREF="/web/"

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl pkg-config libssl-dev && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq
ENV PATH="/root/.cargo/bin:${PATH}"

COPY . /app
WORKDIR /app
RUN DEBIAN_FRONTEND=noninteractive apt update && \
    apt install -y openssh-client && \
    rm -rf assets/js/* && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh,required=true ./scripts/prepare-web.sh
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
