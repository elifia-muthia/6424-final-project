#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="fithealthtdx"
ZONE="us-central1-a"
INSTANCE_NAME="fithealth-tdx-vm"
MACHINE_TYPE="c3-standard-4"
IMAGE_PROJECT="debian-cloud"
IMAGE_FAMILY="debian-12"
CONTAINER_IMAGE="gcr.io/${PROJECT_ID}/fithealth:latest"
SECRET_NAME="projects/${PROJECT_ID}/secrets/fithealth-sqlcipher-key"
STARTUP_SCRIPT="startup_fithealth.sh"
FIREWALL_RULE="allow-fithealth-http"

# 1. Firewall for HTTP port 80
if ! gcloud compute firewall-rules list --filter="name=${FIREWALL_RULE}" \
     --format="value(name)" | grep -q "${FIREWALL_RULE}"; then
  gcloud compute firewall-rules create ${FIREWALL_RULE} \
    --project=${PROJECT_ID} \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --description="Allow HTTP to FitHealth service"
fi

# 2. Create Confidential VM
gcloud compute instances create ${INSTANCE_NAME} \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --min-cpu-platform="Intel Ice Lake" \
  --confidential-compute \
  --image-family=${IMAGE_FAMILY} \
  --image-project=${IMAGE_PROJECT} \
  --boot-disk-size=50GB \
  --metadata-from-file=startup-script=${STARTUP_SCRIPT} \
  --metadata=CONTAINER_IMAGE=${CONTAINER_IMAGE},SECRET_NAME=${SECRET_NAME} \
  --scopes=cloud-platform

echo "Waiting ~60s for VM initialization..."
sleep 60

gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE}
echo "Deployment complete."
