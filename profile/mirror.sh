#!/usr/bin/env bash
set -e

# ==============================================================================
# Inpui Disaster Recovery Mirror Script
# This script pulls all the necessary upstream dependencies for Core, Supervisor,
# and Runtime, tags them, and pushes them to your private registry.
# ==============================================================================

TARGET_REGISTRY="ghcr.io/siksil"
SOURCE_REGISTRY="ghcr.io/home-assistant"
ARCHS=("amd64" "aarch64")

# Update these versions to match the latest upstream releases whenever you run a backup
BASE_VERSION="2026.01.0"      # For 'homeassistant-base' (Core) and 'base' (Supervisor)
HASSFEST_VERSION="2026.01.0"  # Core CI/CD validation tool

# Supervisor Runtime Plugins (Versions change independently)
DNS_VERSION="2024.04.0"
MULTICAST_VERSION="2024.03.0"
AUDIO_VERSION="2024.04.0"
OBSERVER_VERSION="2023.06.0"
CLI_VERSION="2024.03.0"

echo "=========================================="
echo " Starting Inpui Infrastructure Mirror"
echo " Target Registry: ${TARGET_REGISTRY}"
echo "=========================================="

mirror_image() {
  local image_name=$1
  local version=$2
  
  for arch in "${ARCHS[@]}"; do
    local src="${SOURCE_REGISTRY}/${arch}-${image_name}:${version}"
    local dest="${TARGET_REGISTRY}/${arch}-${image_name}:${version}"
    
    echo "-> Mirroring [${arch}] ${image_name}:${version}..."
    if docker pull "${src}" > /dev/null 2>&1; then
      docker tag "${src}" "${dest}"
      docker push "${dest}" > /dev/null 2>&1
      echo "   ✓ Successfully mirrored"
    else
      echo "   ! Warning: Could not pull ${src}. Check version tag."
    fi
  done
}

# 1. Mirror Build Base Images
echo ""
echo "--- Mirroring Build Dependencies ---"
mirror_image "homeassistant-base" "${BASE_VERSION}"
mirror_image "base" "${BASE_VERSION}"

# 2. Mirror CI/CD Tools (Non-arch specific)
echo ""
echo "-> Mirroring hassfest CI tool..."
docker pull "${SOURCE_REGISTRY}/hassfest:${HASSFEST_VERSION}" > /dev/null 2>&1
docker tag "${SOURCE_REGISTRY}/hassfest:${HASSFEST_VERSION}" "${TARGET_REGISTRY}/hassfest:${HASSFEST_VERSION}"
docker push "${TARGET_REGISTRY}/hassfest:${HASSFEST_VERSION}" > /dev/null 2>&1
echo "   ✓ Successfully mirrored"

# 3. Mirror Supervisor Runtime Plugins
echo ""
echo "--- Mirroring Supervisor Runtime Plugins ---"
mirror_image "plugin-dns" "${DNS_VERSION}"
mirror_image "plugin-multicast" "${MULTICAST_VERSION}"
mirror_image "plugin-audio" "${AUDIO_VERSION}"
mirror_image "plugin-observer" "${OBSERVER_VERSION}"
mirror_image "plugin-cli" "${CLI_VERSION}"

echo ""
echo "=========================================="
echo " Backup Complete!"
echo " All infrastructure dependencies are now safely stored in your account."
echo "=========================================="
