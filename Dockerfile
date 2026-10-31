FROM golang:1.27.3-alpine@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb AS build

# renovate: datasource=github-tags depName=mozilla/nss versioning=regex:^NSS_(?<major>\d+)_(?<minor>\d+)(?:_(?<patch>\d+))?_RTM$
ARG NSS_VERSION=NSS_3_132_RTM

COPY ./builder/ /src/builder/
WORKDIR /src

RUN <<-EOF
  set -eux

  apk --no-cache add \
    ca-certificates \
    curl

  curl -sSfLo certdata.txt \
    "https://raw.githubusercontent.com/mozilla/nss/refs/tags/${NSS_VERSION}/lib/ckfw/builtins/certdata.txt"

  cd builder

  go mod download

  go build \
    -buildvcs=false \
    -ldflags "-s -w -buildid=" \
    -mod=readonly \
    -trimpath \
    -o builder
EOF

RUN --network=none <<-EOF
  set -eux

  ./builder/builder \
    --input certdata.txt \
    --output ca-certificates.crt

  # Install to standard location
  install -Dm644 -t /rootfs/etc/ssl/certs ca-certificates.crt
  ln -s certs/ca-certificates.crt /rootfs/etc/ssl/cert.pem

  # OpenSSL 1.1 compat
  mkdir -p /rootfs/etc/ssl1.1
  ln -s ../ssl/certs /rootfs/etc/ssl1.1/
  ln -s ../ssl/cert.pem /rootfs/etc/ssl1.1/
EOF


FROM scratch AS package
COPY --from=build /rootfs/ /
