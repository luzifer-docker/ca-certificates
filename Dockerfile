FROM golang:1.27.3-alpine AS build

# renovate: datasource=github-tags depName=nss-dev/nss versioning=regex:^NSS_(?<major>\d+)_(?<minor>\d+)(?:_(?<patch>\d+))?_RTM$
ARG NSS_VERSION=NSS_3_131_1_RTM

COPY ./builder/ /src/builder/
WORKDIR /src

RUN <<-EOF
  set -eux

  apk --no-cache add \
    ca-certificates \
    curl

  curl -sSfLo certdata.txt \
    "https://raw.githubusercontent.com/nss-dev/nss/refs/tags/${NSS_VERSION}/lib/ckfw/builtins/certdata.txt"

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
