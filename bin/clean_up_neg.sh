#!/bin/bash -e

suffix=$1
zone=$2
cluster=$3
noconfirm=$4

if [ -z "$zone" ] || [ -z "$suffix" ] || { [ -n "$noconfirm" ] && [ "$noconfirm" != delete ]; }; then
  echo "Usage: clean_up_neg.sh <name> <zone> [cluster? true, other] [delete]"
  echo "       Third argument must be 'true' to delete a cluster."
  echo
  echo "       Setting delete on the fourth argument, will"
  echo "       disable confirmation prompts. Beware."
  exit 1
fi

check_confirm_and_execute () {
  if [ "$noconfirm" == delete ]; then
    echo y | "$@"
  else
    "$@"
  fi
}

list_resources () {
  resource=$1
  resource_type=${2:-compute}
  [ -z "$resource" ] && return
  mapfile -t resources <<<"$(gcloud "$resource_type" "$resource" list \
    --filter "$zone name~'[a-zA-Z0-9-]*-${suffix}'" \
    --format "value(name)")"
  if [ ${#resources[@]} = 0 ] || [ -z "${resources[0]}" ]; then
    >&2 echo "No $resource found"
  else
    echo "${resources[@]}"
  fi
}

list_and_delete_resource () {
  resource=$1
  local zone
  zone=$2
  [ -z "$resource" ] && return
  [ -n "$zone" ] && zone="zone=$zone"
  mapfile -t resources <<<"$(gcloud compute "$resource" list \
    --filter "$zone name~'[a-zA-Z0-9-]*-${suffix}'" \
    --format "value(name)")"

  mapfile -t resources <<<"$(list_resources "$resource")"
  [ -z "${resources[0]}" ] && return

  [ -n "$zone" ] && zone="--$zone" || zone=--global
  check_confirm_and_execute \
    gcloud compute "$resource" delete "${resources[@]}" "$zone"
}

list_and_delete_resource forwarding-rules |& grep -v WARNING
list_and_delete_resource target-http-proxies |& grep -v WARNING
list_and_delete_resource url-maps |& grep -v WARNING
list_and_delete_resource backend-services |& grep -v WARNING
list_and_delete_resource network-endpoint-groups "${zone}" |& grep -v WARNING

if [  "$cluster" = true ]; then
  mapfile -t clusters <<<"$(list_resources clusters container)"
  [ -z "${clusters[0]}" ] && exit
  check_confirm_and_execute \
    gcloud container clusters delete "${clusters[@]}" --zone "${zone}"
fi
