#!/bin/bash

# Variables
source ./00-variables.sh

# Check if the resource group already exists
echo "Checking if [$resourceGroupName] resource group actually exists in the [$subscriptionName] subscription..."

az group show --name $resourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$resourceGroupName] resource group actually exists in the [$subscriptionName] subscription"
  echo "Creating [$resourceGroupName] resource group in the [$subscriptionName] subscription..."

  # Create the resource group
  az group create --name $resourceGroupName --location $location 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$resourceGroupName] resource group successfully created in the [$subscriptionName] subscription"
  else
    echo "Failed to create [$resourceGroupName] resource group in the [$subscriptionName] subscription"
    exit
  fi
else
  echo "[$resourceGroupName] resource group already exists in the [$subscriptionName] subscription"
fi

# Check if the event grid topic exists
echo "Checking if [$topicName] event grid topic actually exists in the [$subscriptionName] subscription..."
eventGridTopicId=$(az eventgrid topic show \
  --name $topicName \
  --resource-group $resourceGroupName \
  --query id \
  --output tsv 2>/dev/null)

# Create event grid topic if it does not exist
if [[ -z $eventGridTopicId ]]; then
  echo "No [$topicName] event grid topic exists in [$subscriptionName] subscription"
  # Create event grid topic
  echo "Creating [$topicName] event grid exists in [$resourceGroupName] resource group..."
  az eventgrid topic create \
    --location $location \
    --name $topicName \
    --resource-group $resourceGroupName \
    --mi-system-assigned \
    --public-network-access $publicNetworkAccess \
    --tags $tags 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$topicName] event grid successfully created in the [$resourceGroupName] resource group"
  else
    echo "Failed to create [$topicName] event grid in the [$resourceGroupName] resource group"
    exit
  fi
else
  echo "[$topicName] event grid topic already exists in [$resourceGroupName] resource group"
fi