#!/bin/bash -ex

########################################
# Set up an envoy enabled cluster on a TD enabled project.
# Note the project needs the proper APIs enabled for the
# envoy injection to work. It is expected healthchecks
# have been enabled with the name $PROJECT_ID-health-check.
########################################

if [[ -z "$1" ]] || [[ "$1" =~ ^-h ]] || [[ $# -lt 4 ]]; then
    echo "-I- Usage: gke-manual-tdinject-setup.sh <project_id> <zone> <cluster_name> <service_name> [network_name]"
    exit
fi

PROJECT_ID=$1
GCP_ZONE=$2
CLUSTER_NAME=$3
SERVICE_NAME=$4
NETWORK_NAME=${5:-default}
NUM_NODES=3

. /usr/local/google/home/pururia/sources/gcloud_flows.sh
########################################
# Work in script dir
cd "$(dirname "$0")"
########################################

########################################
# Create cluster and get credentials to startup kubectl
$gcloud_cmd container clusters create "$CLUSTER_NAME" --zone "$GCP_ZONE" \
  --project "$PROJECT_ID" --num-nodes $NUM_NODES --enable-ip-alias \
  --scopes=https://www.googleapis.com/auth/cloud-platform

$gcloud_cmd container clusters get-credentials "$CLUSTER_NAME" --zone="$GCP_ZONE" --project="$PROJECT_ID"
########################################

########################################
# Create service
# WARNING: Ensure the service NEG is unique. In particular, don't leave the
# default from codelabs. It may hurt.
# After the service is created connect it to an end point, and setup the
# forwarding rule.
wget -q -O - https://storage.googleapis.com/traffic-director/demo/trafficdirector_service_sample.yaml \
  | sed "s/service-test/${SERVICE_NAME}/g" | sed "s/app1/success/g" \
  | kubectl apply -f -

gcloud_set_bs "$PROJECT_ID" "$SERVICE_NAME" "$GCP_ZONE"
########################################

########################################
# Create client, and fire!
PROJECT_NUMBER=$($gcloud_cmd projects describe "$PROJECT_ID" --format="value(projectNumber)")
wget -q -O - https://storage.googleapis.com/traffic-director/demo/trafficdirector_client_sample_xdsv3.yaml \
  | sed "s/PROJECT_NUMBER/$PROJECT_NUMBER/g" \
  | sed "s/NETWORK_NAME/$NETWORK_NAME/g" \
  | kubectl create -f -

# Expect a string success-<something>
BUSYBOX_POD=$(kubectl get po -l run=client -o=jsonpath='{.items[0].metadata.name}')
TEST_CMD="wget -q -O - 10.0.0.1; echo"
output=$(kubectl exec -it "$BUSYBOX_POD" -c busybox -- /bin/sh -c "$TEST_CMD")
if [[ "$output" =~ ^success ]]; then
  echo Success
else
  echo "Failed: $output"
fi
########################################
