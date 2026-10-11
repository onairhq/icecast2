# syntax=docker/dockerfile:1

# ============================================================
# Build stage
# ============================================================
FROM alpine:3.23 AS builder

ARG ICECAST_VERSION=2.5.0
ARG LIBIGLOO_VERSION=0.9.5

RUN set -eux; \
    test -n "${ICECAST_VERSION}"; \
    apk add --no-cache \
    autoconf \
    automake \
    build-base \
    curl \
    curl-dev \
    libogg-dev \
    libtheora-dev \
    libtool \
    libvorbis-dev \
    libxml2-dev \
    libxslt-dev \
    openssl-dev \
    pkgconf \
    rhash-dev \
    speex-dev

# ------------------------------------------------------------
# Build libigloo
# ------------------------------------------------------------
WORKDIR /tmp

RUN set -eux; \
    curl -fsSL \
    "https://downloads.xiph.org/releases/igloo/libigloo-${LIBIGLOO_VERSION}.tar.gz" \
    -o libigloo.tar.gz; \
    tar -xzf libigloo.tar.gz; \
    rm libigloo.tar.gz; \
    cd "/tmp/libigloo-${LIBIGLOO_VERSION}"; \
    ./configure \
    --prefix=/usr \
    --disable-static; \
    make -j"$(nproc)"; \
    make DESTDIR=/tmp/rootfs install

# ------------------------------------------------------------
# Download Icecast
# ------------------------------------------------------------
WORKDIR /tmp

RUN set -eux; \
    curl -fsSL \
    "https://downloads.xiph.org/releases/icecast/icecast-${ICECAST_VERSION}.tar.gz" \
    -o icecast.tar.gz; \
    tar -xzf icecast.tar.gz; \
    rm icecast.tar.gz

# ------------------------------------------------------------
# Build Icecast
# ------------------------------------------------------------
WORKDIR /tmp/icecast-${ICECAST_VERSION}

RUN set -eux; \
    export PKG_CONFIG_PATH="/tmp/rootfs/usr/lib/pkgconfig:/tmp/rootfs/usr/share/pkgconfig"; \
    export CPPFLAGS="-I/tmp/rootfs/usr/include"; \
    export LDFLAGS="-L/tmp/rootfs/usr/lib"; \
    ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --disable-static; \
    make -j"$(nproc)"; \
    make DESTDIR=/tmp/rootfs install

# ============================================================
# Runtime stage
# ============================================================
FROM alpine:3.23

ARG ICECAST_VERSION=2.5.0

ENV ICECAST_VERSION="${ICECAST_VERSION}"

LABEL org.opencontainers.image.title="Icecast2" \
    org.opencontainers.image.description="Icecast2 streaming media server" \
    org.opencontainers.image.version="${ICECAST_VERSION}" \
    org.opencontainers.image.source="https://github.com/onairhq/icecast2"

# ============================================================
# Runtime dependencies
# ============================================================
RUN apk add --no-cache \
    bash \
    ca-certificates \
    libcurl \
    libogg \
    libtheora \
    libvorbis \
    libxml2 \
    libxslt \
    openssl \
    rhash-libs \
    speex

# ============================================================
# Install Icecast and libigloo
# ============================================================
COPY --from=builder /tmp/rootfs/ /

# ============================================================
# Redirect logs to stdout/stderr
# ============================================================
RUN set -eux; \
    mkdir -p /var/log/icecast; \
    ln -sf /dev/stdout /var/log/icecast/access.log; \
    ln -sf /dev/stderr /var/log/icecast/error.log

# ============================================================
# User and runtime directories
# ============================================================
RUN set -eux; \
    addgroup -S -g 10001 icecast; \
    adduser -S -D -H \
    -u 10001 \
    -G icecast \
    -h /var/lib/icecast \
    -s /sbin/nologin \
    icecast; \
    mkdir -p \
    /var/lib/icecast \
    /var/log/icecast \
    /var/run/icecast; \
    chown -R icecast:icecast \
    /etc/icecast.xml \
    /var/lib/icecast \
    /var/log/icecast \
    /var/run/icecast; \
    chmod 0644 /etc/icecast.xml; \
    chown icecast:icecast /etc; \
    chmod 0755 /etc

# ============================================================
# Entrypoint
# ============================================================
COPY xml_editor.sh /usr/local/bin/xml_editor
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod 0755 \
    /usr/local/bin/xml_editor \
    /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/lib/icecast

EXPOSE 8000

STOPSIGNAL SIGTERM

USER 10001:10001

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["icecast", "-c", "/etc/icecast.xml"]
