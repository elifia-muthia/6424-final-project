#!/usr/bin/env bash
set -euo pipefail

# Fetch metadata
CONTAINER_IMAGE="$(curl -s -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/CONTAINER_IMAGE)"
SECRET_NAME="$(curl -s -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/SECRET_NAME)"

# 1. Install packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https ca-certificates curl gnupg lsb-release \
  python3 python3-pip software-properties-common

# 2. Install Docker
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# 3. Install Intel TDX CLI
curl -fsSL https://downloads.intel.com/tdx-attestation/cli/install.sh | bash

# 4. Prepare data volume
mkdir -p /mnt/data

# 5. Run container (plain HTTP, no certs)
docker pull ${CONTAINER_IMAGE}
docker run -d \
  --name fithealth \
  --cap-add=INTEL_TDX \
  --device=/dev/tdx_guest \
  -e SECRET_NAME="${SECRET_NAME}" \
  -e GOOGLE_APPLICATION_CREDENTIALS="/etc/google/auth/application_default_credentials.json" \
  -v /mnt/data:/data \
  -p 80:80 \
  ${CONTAINER_IMAGE}

# 6. Stream logs
docker logs -f fithealth
