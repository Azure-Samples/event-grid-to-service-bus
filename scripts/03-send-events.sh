#!/bin/bash

# Variables
source ./00-variables.sh

json="["
for ((i=0;i<${#tenants[@]};i++)); do
    ((id=id+1))
    subject="atom/events/${tenants[$i],,}"
    eventTime=$(date +%FT%T.%3N%:z)
    data="{\"tenant\":\"${tenants[$i]}\",\"date\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}"
    event="{
    \"id\":\"$id\",
    \"eventType\":\"$eventType\",
    \"subject\":\"$subject\",
    \"eventTime\":\"$eventTime\",
    \"data\": $data
    }"
    if [ $i == 0 ]
    then
        json=$json$event
    else
        json=$json,$event
    fi
done
json=$json"]"
json=$(echo $json | sed 's/ //g')

# Retrieve the endpoint of the event grid topic
echo "Retrieving the endpoint of the [$topicName] event grid topic..."
endpoint=$(az eventgrid topic show \
  --name $topicName \
  --resource-group $resourceGroupName \
  --query endpoint \
  --output tsv 2>/dev/null)

if [[ -n $endpoint ]]; then
  echo "[$endpoint] endpoint of the [$topicName] event grid topic successfully retrieved"
else
  echo "Failed to retrieve the endpoint of the [$topicName] event grid topic"
  exit
fi

# Retrieve the key of the event grid topic
echo "Retrieving the key of the [$topicName] event grid topic..."
key=$(az eventgrid topic key list \
  --name $topicName \
  --resource-group $resourceGroupName \
  --query key1 \
  --output tsv 2>/dev/null)

if [[ -n $key ]]; then
  echo "[$key] key of the [$topicName] event grid topic successfully retrieved"
else
  echo "Failed to retrieve the key of the [$topicName] event grid topic"
  exit
fi

# Send events to the event grid topic
echo "Sending events to the [$topicName] event grid topic..."
echo $json | jq -r

curl -X POST \
  -H "aeg-sas-key: $key" \
  -H "Content-Type: application/json" \
  -d "$json" \
  $endpoint