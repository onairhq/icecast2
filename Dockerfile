# syntax=docker/dockerfile:1

ARG ALPINE_VERSION=3.23

# ------------------------------------------------------------
# Build stage
# ------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS builder

ARG ICECAST_VERSION=2.5.0
ARG LIBIGLOO_VERSION=0.9.5

ENV PREFIX=/usr
ENV PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib64/pkgconfig

RUN apk add --no-cache \
    build-base \
    autoconf \
    automake \
    libtool \
    pkgconf \
    linux-headers \
    curl \
    tar \
    bzip2 \
    ca-certificates \
    curl-dev \
    libogg-dev \
    libtheora-dev \
    libvorbis-dev \
    libxml2-dev \
    libxslt-dev \
    openssl-dev \
    rhash-dev \
    speex-dev

WORKDIR /build

# Download and compile libigloo.
RUN set -eux; \
    curl -fsSL \
    "https://downloads.xiph.org/releases/igloo/libigloo-${LIBIGLOO_VERSION}.tar.gz" \
    -o libigloo.tar.gz; \
    mkdir libigloo-src; \
    tar -xzf libigloo.tar.gz \
    --strip-components=1 -C libigloo-src; \
    cd libigloo-src; \
    ./configure --prefix=/usr; \
    make -j"$(getconf _NPROCESSORS_ONLN)"; \
    make install

# Download and compile Icecast.
RUN set -eux; \
    curl -fsSL \
    "https://downloads.xiph.org/releases/icecast/icecast-${ICECAST_VERSION}.tar.gz" \
    -o icecast.tar.gz; \
    mkdir icecast-src; \
    tar -xzf icecast.tar.gz \
    --strip-components=1 -C icecast-src; \
    cd icecast-src; \
    PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/lib64/pkgconfig" \
    ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var; \
    make -j"$(getconf _NPROCESSORS_ONLN)"; \
    make install

# ------------------------------------------------------------
# Runtime stage
# ------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS runtime

ENV PATH="/usr/bin:/usr/sbin:/bin:/sbin"
ENV LD_LIBRARY_PATH="/usr/lib"

RUN apk add --no-cache \
    ca-certificates \
    curl \
    libogg \
    libtheora \
    libvorbis \
    libxml2 \
    libxslt \
    openssl \
    rhash-libs \
    speex \
    libgcc \
    libstdc++

# Fixed non-root identity.
RUN addgroup -S -g 10001 icecast \
    && adduser -S -D -H \
    -u 10001 \
    -G icecast \
    -s /sbin/nologin \
    icecast

# Copy the compiled application and libigloo from the builder.
COPY --from=builder /usr/bin/icecast /usr/bin/icecast
COPY --from=builder /usr/lib/ /usr/lib/
COPY --from=builder /usr/share/icecast/ /usr/share/icecast/

# Original configuration remains protected.
COPY --chown=root:icecast icecast.xml /etc/icecast.xml

RUN chmod 0640 /etc/icecast.xml \
    && mkdir -p \
    /var/lib/icecast \
    /var/log/icecast \
    /var/run/icecast \
    && chown -R icecast:icecast \
    /var/lib/icecast \
    /var/log/icecast \
    /var/run/icecast \
    && chmod 0750 \
    /var/lib/icecast \
    /var/log/icecast \
    /var/run/icecast

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY xml-edit.sh /usr/local/bin/xml-edit

RUN chmod 0755 \
    /usr/local/bin/docker-entrypoint.sh \
    /usr/local/bin/xml-edit

EXPOSE 8000

USER 10001:10001

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["icecast", "-c", "/var/lib/icecast/icecast.xml"]
