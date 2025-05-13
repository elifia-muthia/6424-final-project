#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="fithealthtdx"
ZONE="us-east5-b"
INSTANCE_NAME="fithealth-tdx-vm"
MACHINE_TYPE="c3-standard-4"
IMAGE_PROJECT="ubuntu-os-cloud"
IMAGE_FAMILY="ubuntu-2204-lts"
CONTAINER_IMAGE="us-central1-docker.pkg.dev/${PROJECT_ID}/fithealth-repo/fithealth:latest"
SECRET_NAME="projects/${PROJECT_ID}/secrets/fithealth-sqlcipher-key"
STARTUP_SCRIPT="startup_fithealth.sh"
FIREWALL_RULE="allow-fithealth-https"

# 1. Firewall for HTTP port 80
if ! gcloud compute firewall-rules list --filter="name=${FIREWALL_RULE}" \
     --format="value(name)" | grep -q "${FIREWALL_RULE}"; then
  gcloud compute firewall-rules create ${FIREWALL_RULE} \
    --project=${PROJECT_ID} \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --description="Allow HTTPs to FitHealth service"
fi

# 2. Create Confidential VM
gcloud compute instances create ${INSTANCE_NAME} \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --maintenance-policy TERMINATE \
  --confidential-compute-type=TDX \
  --image-family=${IMAGE_FAMILY} \
  --image-project=${IMAGE_PROJECT} \
  --boot-disk-size=50GB \
  --metadata-from-file=startup-script=${STARTUP_SCRIPT} \
  --metadata=CONTAINER_IMAGE=${CONTAINER_IMAGE},SECRET_NAME=${SECRET_NAME} \
  --scopes=cloud-platform \
  --service-account=fithealth-vm-sa@${PROJECT_ID}.iam.gserviceaccount.com

echo "Waiting ~60s for VM initialization..."
sleep 60

gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE}
echo "Deployment complete."
