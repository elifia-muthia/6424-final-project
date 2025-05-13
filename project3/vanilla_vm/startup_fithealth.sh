#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/fithealth-startup.log"
exec > >(tee -a "$LOGFILE") 2>&1

REPO_URL="https://github.com/elifia-muthia/6424-final-project.git"
APP_DIR="6424-final-project/project3/vanilla_vm"
IMAGE_TAG="fithealth:vanilla"

echo "Installing OS prerequisites..."
apt-get update
apt-get install --only-upgrade ca-certificates git libcurl4
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common

echo "Installing Docker..."
install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io

echo "Starting Docker service..."
systemctl enable --now docker
sleep 5

echo "Cloning & building the Docker image..."
git clone "${REPO_URL}"
cd "${APP_DIR}"

echo "Configuring gcloud for Artifact Registry (if you pull images)..."
# only needed if you later docker pull; harmless otherwise
gcloud auth configure-docker us-central1-docker.pkg.dev

echo "Preparing data & cert directories..."
mkdir -p /mnt/data /certs

echo "Fetching TLS certs from GCS..."
sudo gsutil cp gs://fithealthtdx-certs/server.crt /certs/server.crt
sudo gsutil cp gs://fithealthtdx-certs/server.key  /certs/server.key
chmod 600 /certs/server.key

echo "Building FitHealth..."
docker build -t "${IMAGE_TAG}" .

echo "Preparing data collection on CPU/Memory usage..."
mkdir -p /mnt/data
rm -rf /mnt/data/metrics.log
touch /mnt/data/metrics.log
chmod 666 /mnt/data/metrics.log

echo "Running the FitHealth container on HTTPS (443)..."
docker rm -f fithealth 2>/dev/null || true
docker run -d \
  --name fithealth \
  -v /mnt/data:/data \
  -v /certs:/certs:ro \
  -v /mnt/data/metrics.log:/var/log/metrics.log:rw \
  -e GOOGLE_CLOUD_PROJECT="$(curl -s -H 'Metadata-Flavor: Google' \
      http://metadata.google.internal/computeMetadata/v1/project/project-id)" \
  -p 443:443 \
  "${IMAGE_TAG}"

echo "FitHealth service started on HTTPS port 443."
