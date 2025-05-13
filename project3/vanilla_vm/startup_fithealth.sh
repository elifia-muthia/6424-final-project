#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/fithealth-startup.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Fetching metadata for container image..."
CONTAINER_IMAGE="$(curl -s -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/CONTAINER_IMAGE)"

echo "Installing Docker prerequisites..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common

echo "Adding Docker’s APT repo..."
install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

echo "Installing Docker..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io

echo "Starting Docker service..."
systemctl enable --now docker
sleep 5

echo "Configuring gcloud for Artifact Registry..."
gcloud auth configure-docker us-central1-docker.pkg.dev

echo "Preparing data & cert directories..."
mkdir -p /mnt/data /certs

echo "Fetching TLS certificates from GCS..."
gsutil cp gs://fithealth-certs/server.crt /certs/server.crt
gsutil cp gs://fithealth-certs/server.key  /certs/server.key
chmod 600 /certs/server.key

echo "Pulling & running FitHealth container on HTTPS (443)..."
docker pull "${CONTAINER_IMAGE}"
docker rm -f fithealth 2>/dev/null || true
docker run -d \
  --name fithealth \
  -v /mnt/data:/data \
  -v /certs:/certs:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS="/etc/google/auth/application_default_credentials.json" \
  -p 443:443 \
  "${CONTAINER_IMAGE}"

echo "FitHealth service started on HTTPS port 443."
