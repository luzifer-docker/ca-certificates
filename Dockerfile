FROM scratch AS build
COPY --from=stagex/core-busybox         . /
COPY --from=stagex/core-ca-certificates . /
COPY --from=stagex/core-curl            . /
COPY --from=stagex/core-libzstd         . /
COPY --from=stagex/core-musl            . /
COPY --from=stagex/core-openssl         . /
COPY --from=stagex/core-perl            . /
COPY --from=stagex/core-zlib            . /

# renovate: datasource=github-tags depName=curl/curl versioning=regex:^curl-(?<major>\d+)_(?<minor>\d+)_(?<patch>\d+)$
ARG CURL_VERSION=curl-8_19_0
# renovate: datasource=github-tags depName=nss-dev/nss versioning=regex:^NSS_(?<major>\d+)_(?<minor>\d+)(?:_(?<patch>\d+))?_RTM$
ARG NSS_VERSION=NSS_3_122_1_RTM

WORKDIR /src

RUN curl -sSfLo certdata.txt    "https://raw.githubusercontent.com/nss-dev/nss/refs/tags/${NSS_VERSION}/lib/ckfw/builtins/certdata.txt"
RUN curl -sSfLo mk-ca-bundle.pl "https://raw.githubusercontent.com/curl/curl/refs/tags/${CURL_VERSION}/scripts/mk-ca-bundle.pl"

RUN --network=none <<-EOF
	set -eux

  # Build cert-bundle from downloaded certdata.txt
  perl mk-ca-bundle.pl -n -f ca-certificates.crt

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
