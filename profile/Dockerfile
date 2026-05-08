# Universal Proxy Dockerfile for Inpui Infrastructure Mirroring
#
# If you prefer to formally rebuild the images to bake your own metadata
# into the layers (instead of just running the shell script), use this file.
#
# Usage Example (Building the DNS Plugin):
# docker build --build-arg SOURCE_IMAGE=ghcr.io/home-assistant/amd64-plugin-dns:2024.04.0 -t ghcr.io/siksil/amd64-plugin-dns:2024.04.0 .

ARG SOURCE_IMAGE
FROM ${SOURCE_IMAGE}

# Overwrite upstream metadata with Inpui branding
LABEL \
    org.opencontainers.image.vendor="Inpui" \
    org.opencontainers.image.title="Inpui Core Infrastructure" \
    org.opencontainers.image.description="Disaster Recovery Mirror for the Inpui Ecosystem" \
    org.opencontainers.image.url="https://www.siksil.cloud" \
    org.opencontainers.image.documentation="https://www.siksil.cloud/docs/"
