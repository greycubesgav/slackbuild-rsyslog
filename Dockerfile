FROM greycubesgav/slackware-docker-base:latest AS builder

# Setup the version of rsyslog to build
ARG RSYSLOG_VERSION
ENV RSYSLOG_VERSION=$RSYSLOG_VERSION

# Install the dependancies binaries for the build
COPY src /root/src/

# Setup the build environment
ENV TAG='_GG'

# Install package requirements
RUN echo 'y' | slackpkg install gnutls nettle

# Build the base libraries
# libestr
WORKDIR /root/src/libestr
RUN VERSION=0.1.9 ./libestr.SlackBuild
RUN installpkg /tmp/libestr-*-x86_64-1_GG.tgz

# libfastjson
WORKDIR /root/src/libfastjson
RUN VERSION=0.99.9 ./libfastjson.SlackBuild
RUN installpkg /tmp/libfastjson-*-x86_64-1_GG.tgz

# Build and install p11-kit for rsyslog build
WORKDIR /root/src/
RUN tar -xJf p11-kit-*.tar.xz
WORKDIR /root/src/p11-kit-0.25.5
RUN meson setup _build -Dsystemd=disabled -Dbash_completion=disabled --prefix=/usr && meson compile -C _build && meson install -C _build

# Build rsyslog
WORKDIR /root/src/rsyslog
RUN VERSION=${RSYSLOG_VERSION} GNUTLS=yes ./rsyslog.SlackBuild

#ENTRYPOINT [ "bash" ]

# Create a clean image with only the artifact
FROM scratch AS artifact
COPY --from=builder /tmp/rsyslog*.tgz .