# luzifer-docker / ca-certificates

This repository builds a minimal container image containing the Mozilla-managed CA certificate bundle for use in `scratch`-based images.

The published image is available as `ghcr.io/luzifer-docker/ca-certificates` and is designed to be copied into another image instead of being run directly.

## Purpose

Use this image when you need a standard CA trust store inside a `scratch` image. It provides the certificate bundle and compatibility symlinks in common OpenSSL locations.

## Contents

The published image contains:

- `/etc/ssl/certs/ca-certificates.crt`
- `/etc/ssl/cert.pem` as a symlink to the certificate bundle
- `/etc/ssl1.1` symlinks for OpenSSL 1.1 compatibility

## Build

The bundle is generated from Mozilla NSS `certdata.txt` using curl's `mk-ca-bundle.pl` script.

The build assembles the required tooling in an intermediate stage, generates the certificate bundle, installs the resulting files into a root filesystem, and publishes a final `FROM scratch` image containing only those prepared files.

Changes to `Dockerfile` on `develop` trigger tag creation based on `NSS_VERSION`. CI then builds and publishes the image to GitHub Container Registry. Dependency updates for the build inputs are managed with Renovate.

## Usage

```Dockerfile
FROM scratch
COPY --from=ghcr.io/luzifer-docker/ca-certificates:3.123.0 / /
```

Replace the tag with the release you want to consume in your image.
