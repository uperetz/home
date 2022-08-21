#!/bin/bash -ex

########################################
# Create an observability enabled project. This is a one time thing for a given
# PROJECT_ID.
# Load up our project. The alias is to handle the secret, worse gcloud in your
# path.
########################################

if [[ -z "$1" ]] || [[ "$1" =~ ^-h ]]; then
    echo "-I- Usage: observability-project-setup.sh <project_id>"
    exit
fi

PROJECT_ID=$1

gcloud_cmd='/google/data/ro/teams/cloud-sdk/gcloud'
function whitelist-obs () {
  # This function whitelists service acount SERVICE_MAIL to report metrics for
  # PROJECT_ID. These need to be defined in the environment.
  curl \
    -H "Authorization: Bearer $($gcloud_cmd auth print-access-token --project "$PROJECT_ID")" \
    -H "Content-Type: application/json" \
    -d "{
      'policy': {
        'bindings': [ {
          role: 'roles/servicemanagement.reporter',
          members: 'serviceAccount:$SERVICE_EMAIL'
        } ]
      }
    }" \
    "https://servicemanagement.googleapis.com/v1/services/networkobservability.googleapis.com/consumers/${PROJECT_ID}:setIamPolicy"

}

########################################
# Create the project
/google/bin/releases/cloud-sdn-management-prod/prober_maker/prober_maker create_project --project_id "$PROJECT_ID"
########################################

########################################
# This enables all the APIs we could possibly need.
# There is a non-negligible chance this is too much.
$gcloud_cmd services enable \
  dns.googleapis.com \
  container.googleapis.com \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  trafficdirector.googleapis.com \
  networkservices.googleapis.com \
  networksecurity.googleapis.com \
  privateca.googleapis.com \
  staging-compute.sandbox.googleapis.com \
  gkehub.googleapis.com --project "$PROJECT_ID"
########################################

########################################
# Enable traffic director, Chemist reporting, and observability reporting for
# service account. Note there are 2 - the one listed by the below command, is
# not the one actually used by cloud services for stuff # on GKE for example.
# We enable for both, just to be safe.
#
# After we enable the APIs, observability needs to be whitelisted specifically
# as it does not follow the usual cloud API enablement.
SERVICE_EMAIL=$($gcloud_cmd iam service-accounts list --project "$PROJECT_ID" --format="value(EMAIL)")
$gcloud_cmd projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:$SERVICE_EMAIL" \
  --role=roles/trafficdirector.client \
  --role=roles/networkobservability.telemetrySamplesReporter \
  --role=roles/servicemanagement.serviceController # TD, observability, and Chemist reporting, in otder
whitelist-obs

SERVICE_EMAIL=${SERVICE_EMAIL/-compute@/@}
SERVICE_EMAIL=${SERVICE_EMAIL/@developer./@cloudservices.}
$gcloud_cmd projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:$SERVICE_EMAIL" \
  --role=roles/trafficdirector.client \
  --role=roles/networkobservability.telemetrySamplesReporter \
  --role=roles/servicemanagement.serviceController
whitelist-obs
########################################

########################################
# Enable health checks, needed by TD.
$gcloud_cmd compute health-checks create http "$PROJECT_ID-health-check"  --use-serving-port --project "$PROJECT_ID"

# This will allow health checks on all networks
$gcloud_cmd compute firewall-rules create fw-allow-health-checks --action ALLOW --direction INGRESS \
               --source-ranges 35.191.0.0/16,130.211.0.0/22 --rules tcp --project "$PROJECT_ID"
########################################

########################################
# Finally, we add an observability policy. As long as we have at least one with
# serviceGraph enabled, we're good to go.
$gcloud_cmd config set api_endpoint_overrides/networkservices  https://networkservices.googleapis.com/

obs_fname=/tmp/$USER-$$-observability-policy
cat << EOF >> "$obs_fname"
serviceGraph: {enabled: true}
scope: PROJECT
name: enable-observability
EOF

$gcloud_cmd alpha network-services observability-policies \
  import myObservabilityPolicy --project "$PROJECT_ID" \
  --source="$obs_fname" --location=global

rm "$obs_fname"
########################################
