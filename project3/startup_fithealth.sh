#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/fithealth-startup.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Fetching metadata..."
CONTAINER_IMAGE="$(curl -s -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/CONTAINER_IMAGE)"
SECRET_NAME="$(curl -s -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/SECRET_NAME)"

echo "Updating packages and installing dependencies..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https ca-certificates curl gnupg lsb-release \
  python3 python3-pip software-properties-common

echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "Waiting for Docker service to start..."
systemctl start docker
systemctl enable docker
sleep 5

echo "Docker version:"
docker --version

gcloud auth configure-docker us-central1-docker.pkg.dev

echo "Pulling container image: ${CONTAINER_IMAGE}"
docker pull "${CONTAINER_IMAGE}"

echo "Running container..."
docker run -d \
  --name fithealth \
  --device=/dev/tdx_guest \
  -e SECRET_NAME="${SECRET_NAME}" \
  -e GOOGLE_APPLICATION_CREDENTIALS="/etc/google/auth/application_default_credentials.json" \
  -v /mnt/data:/data \
  -p 80:80 \
  "${CONTAINER_IMAGE}"

echo "Container started successfully."

echo "Setup complete."
