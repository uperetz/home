#!/bin/bash

PROJECT_ID=$1
SERVICE_ACCOUNT=$2

if [ -z "$PROJECT_ID" ] || [ -z "$SERVICE_ACCOUNT" ]; then
  echo "grant_service_obs_auth.sh <project_id> <service_account>"
  exit 1
fi

. ~/.bashrc.private
gcurl -d "{
  'policy': {
    'bindings': [ {
      role: 'roles/servicemanagement.reporter',
      members: 'serviceAccount:$SERVICE_ACCOUNT'
    } ]
  }
}" "https://servicemanagement.googleapis.com/v1/services/networkobservability.googleapis.com/consumers/$PROJECT_ID:setIamPolicy"
