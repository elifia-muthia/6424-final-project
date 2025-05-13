#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/fithealth-startup.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Updating apt and installing Docker..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

# Docker repo
install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io

echo "Starting Docker..."
systemctl enable --now docker
sleep 5

echo "Preparing directories..."
mkdir -p /mnt/data /certs

echo "Fetching TLS certificates from GCS..."
# adjust your bucket/name if needed
gsutil cp gs://fithealth-certs/server.crt /certs/server.crt
gsutil cp gs://fithealth-certs/server.key  /certs/server.key
chmod 600 /certs/server.key

echo "Pulling and running FitHealth container..."
CONTAINER_IMAGE="${CONTAINER_IMAGE:-us-central1-docker.pkg.dev/fithealthtdx/fithealth-repo/fithealth:latest}"
docker pull "${CONTAINER_IMAGE}"
docker run -d \
  --name fithealth \
  -v /mnt/data:/data \
  -v /certs:/certs:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS="/etc/google/auth/application_default_credentials.json" \
  -p 80:80 \
  "${CONTAINER_IMAGE}"

echo "FitHealth service started on port 80."
