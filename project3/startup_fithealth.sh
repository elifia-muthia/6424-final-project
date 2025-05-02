#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/fithealth-startup.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Fetching metadata..."
CONTAINER_IMAGE="$(curl -s -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/CONTAINER_IMAGE)"
SECRET_NAME="$(curl -s -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/SECRET_NAME)"

echo "Installing Docker..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https ca-certificates linux-modules-extra-gcp curl gnupg lsb-release software-properties-common

modprobe tdx_guest
mount -t configfs configfs /sys/kernel/config 2>/dev/null || true

# Docker repo & install
install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  docker-ce docker-ce-cli containerd.io

echo "Starting Docker..."
systemctl enable --now docker
sleep 5
docker --version

echo "Configuring gcloud auth for Artifact Registry..."
gcloud auth configure-docker us-central1-docker.pkg.dev

echo "Preparing directories..."
mkdir -p /mnt/data /certs

echo "Fetching TLS certificates from GCS..."
gsutil cp gs://fithealthtdx-certs/server.crt /certs/server.crt
gsutil cp gs://fithealthtdx-certs/server.key  /certs/server.key
chmod 600 /certs/server.key

echo "Pulling and running FitHealth container over HTTPS..."
docker pull "${CONTAINER_IMAGE}"
docker run -d \
  --name fithealth \
  --mount type=bind,source=/sys/kernel/config,target=/sys/kernel/config \
  --cap-add SYS_ADMIN \
  --cap-add MKNOD \
  --security-opt seccomp=unconfined \
  -e SECRET_NAME="${SECRET_NAME}" \
  -e GOOGLE_APPLICATION_CREDENTIALS="/etc/google/auth/application_default_credentials.json" \
  -v /mnt/data:/data \
  -v /certs:/certs:ro \
  -p 443:443 \
  "${CONTAINER_IMAGE}"

echo "FitHealth service started on HTTPS port 443."
