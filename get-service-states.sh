#!/bin/bash

get_service_states() {
  # get service plans as list
  SERVICE_OFFERING=$(cf curl '/v3/service_offerings?per_page=5000' | jq -r '.resources[] | select(.name=='\"$PLAN\"').guid')
  SERVICE_PLANS=$(cf curl "/v3/service_plans?per_page=5000&service_offering_guids=$SERVICE_OFFERING" | jq -r '.resources[].guid' | tr '\n' ',')

  # get service instance GUIDs
  INSTANCES=$(cf curl "/v3/service_instances?per_page=5000&service_plan_guids=$SERVICE_PLANS" | jq -r '.resources[].guid')

  # print instance info if state matches
  for is in $INSTANCES; do
    is_state=$(cf curl "/v3/service_instances/$is" | jq -r '.last_operation.state')
    if [[ $is_state = $STATE ]] || [[ $STATE = "" ]];
    then
      is_space_guid=$(cf curl "/v3/service_instances/$is" | jq -r '.relationships.space.data.guid')
      is_org_guid=$(cf curl "/v3/spaces/$is_space_guid" | jq -r '.relationships.organization.data.guid')
      echo SERVICE NAME: $(cf curl "/v3/service_instances/$is" | jq -r '.name')
      echo STATE: $is_state
      echo SPACE: $(cf curl "/v3/spaces/$is_space_guid" | jq -r '.name')
      echo ORG: $(cf curl "/v3/organizations/$is_org_guid" | jq -r '.name')
      echo
    fi
  done
}

STATE=""
while getopts ":p:s:" opt; do
  case $opt in
    p)
    PLAN="$OPTARG"
    ;;

    s)
    STATE="$OPTARG"
    ;;

    *)
    exit 1
    ;;
  esac
done

get_service_states
