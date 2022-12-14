#!/bin/bash

# Variables
source ./00-variables.sh

# Check if the event grid topic exists
echo "Checking if [$topicName] event grid topic actually exists in the [$subscriptionName] subscription..."
resourceId=$(az eventgrid topic show \
  --name $topicName \
  --resource-group $resourceGroupName \
  --query id \
  --output tsv 2>/dev/null)

# Create event grid topic if it does not exist
if [[ -n $resourceId ]]; then
  echo "[$topicName] event grid topic exists in [$resourceGroupName] resource group"
else
  echo "No [$topicName] event grid topic exists in [$subscriptionName] subscription"
  exit
fi

# Check if the resource group already exists
echo "Checking if [$resourceGroupName] resource group actually exists in the [$subscriptionName] subscription..."

az group show --name $resourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$resourceGroupName] resource group actually exists in the [$subscriptionName] subscription"
  echo "Creating [$resourceGroupName] resource group in the [$subscriptionName] subscription..."
  az group create \
    --name $resourceGroupName \
    --location $location 1>/dev/null

  # Create the resource group
  if [[ $? == 0 ]]; then
    echo "[$resourceGroupName] resource group successfully created in the [$subscriptionName] subscription"
  else
    echo "Failed to create [$resourceGroupName] resource group in the [$subscriptionName] subscription"
    exit
  fi
else
  echo "[$resourceGroupName] resource group already exists in the [$subscriptionName] subscription"
fi

# Check if the storage account for deadletter messages exists
echo "Checking if [$storageAccountName] storage account exists for the [$topicName] event grid topic..."
storageAccountId=$(az storage account show \
  --name $storageAccountName \
  --resource-group $resourceGroupName \
  --query id \
  --output tsv 2>/dev/null)

if [[ -z $storageAccountId ]]; then
  # Create Storage Account
  echo "No [$storageAccountName] storage account exists in the [$resourceGroupName] resource group"
  echo "Creating [$storageAccountName] storage account in the [$resourceGroupName] resource group..."

  az storage account create \
    --name $storageAccountName \
    --resource-group $resourceGroupName \
    --query id \
    --output tsv 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$storageAccountName] storage account successfully created in the [$resourceGroupName] resource group"
  else
    echo "Failed to create [$storageAccountName] storage account in the [$resourceGroupName] resource group"
    exit
  fi
else
  echo "[$storageAccountName] storage account already exists in the [$resourceGroupName] resource group"
fi

# Get the storage account key
echo "Retrieving the primary key of the [$storageAccountName] storage account..."
storageAccountKey=$(az storage account keys list \
  --account-name $storageAccountName \
  --resource-group $resourceGroupName \
  --query [0].value -o tsv)

if [[ -n $storageAccountKey ]]; then
  echo "Primary key of the [$storageAccountName] storage account successfully retrieved"
else
  echo "Failed to retrieve the primary key of the [$storageAccountName] storage account"
  exit
fi

# Create the deadletter container
echo "Checking if the [$containerName] container already exists in the [$storageAccountName] storage account..."
name=$(az storage container show \
  --name $containerName \
  --account-name $storageAccountName \
  --account-key $storageAccountKey \
  --query name \
  --output tsv 2>/dev/null)

if [[ -z $name ]]; then
  # Create Storage Account
  echo "No [$containerName] container exists in the [$storageAccountName] storage account"
  echo "Creating [$containerName] container in the [$storageAccountName] storage account..."
  az storage container create \
    --name $containerName \
    --account-name $storageAccountName \
    --account-key $storageAccountKey \
    --query id \
    --output tsv 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$containerName] container successfully created in the [$storageAccountName] storage account"
  else
    echo "Failed to create [$containerName] container in the [$storageAccountName] storage account"
    exit
  fi
else
  echo "[$containerName] container already exists in the [$storageAccountName] storage account"
fi

for tenant in ${tenants[@]}; do

  # Variables
  serviceBusNamespace="${tenant}ServiceBusNamespace"
  eventGridSubscriptionName="${tenant}EventGridSubscription"
  subjectEndsWith="${tenant,,}"

  # Check if the service bus namespace already exists
  echo "Checking if [$serviceBusNamespace] service bus namespace actually exists in the [$subscriptionName] subscription..."

  az servicebus namespace show \
    --name $serviceBusNamespace \
    --resource-group $resourceGroupName &>/dev/null

  if [[ $? != 0 ]]; then
    echo "No [$serviceBusNamespace] service bus namespace actually exists in the [$subscriptionName] subscription"
    echo "Creating [$serviceBusNamespace] service bus namespace in the [$subscriptionName] subscription..."
    az servicebus namespace create \
      --name $serviceBusNamespace \
      --location $location \
      --resource-group $resourceGroupName \
      --mi-system-assigned \
      --sku $serviceBusSku 1>/dev/null

    # Create the service bus namespace
    if [[ $? == 0 ]]; then
      echo "[$serviceBusNamespace] service bus namespace successfully created in the [$subscriptionName] subscription"
    else
      echo "Failed to create [$serviceBusNamespace] service bus namespace in the [$subscriptionName] subscription"
      exit
    fi
  else
    echo "[$serviceBusNamespace] service bus namespace already exists in the [$subscriptionName] subscription"
  fi

  # Check if the service bus queue already exists
  echo "Checking if [$serviceBusQueueName] service bus queue actually exists in the [$serviceBusNamespace] service bus namespace..."

  az servicebus queue show \
    --name $serviceBusQueueName \
    --namespace-name $serviceBusNamespace \
    --resource-group $resourceGroupName &>/dev/null

  if [[ $? != 0 ]]; then
    echo "No [$serviceBusQueueName] service bus queue actually exists in the [$serviceBusNamespace] service bus namespace"
    echo "Creating [$serviceBusQueueName] service bus queue in the [$serviceBusNamespace] service bus namespace..."

    az servicebus queue create \
      --name $serviceBusQueueName \
      --namespace-name $serviceBusNamespace \
      --resource-group $resourceGroupName 1>/dev/null

    # Create the service bus namespace
    if [[ $? == 0 ]]; then
      echo "[$serviceBusQueueName] service bus queue successfully created in the [$serviceBusNamespace] service bus namespace"
    else
      echo "Failed to create [$serviceBusQueueName] service bus queue in the [$serviceBusNamespace] service bus namespace"
      exit
    fi
  else
    echo "[$serviceBusQueueName] service bus queue already exists in the [$serviceBusNamespace] service bus namespace"
  fi

  # Get service bus resource id
  serviceBusId=$(az servicebus queue show \
    --name $serviceBusQueueName \
    --namespace-name $serviceBusNamespace \
    --resource-group $resourceGroupName \
    --query id \
    --output tsv)

  if [[ -n $serviceBusId ]]; then
    echo "Resource id for the [$serviceBusQueueName] service bus queue successfully retrieved"
  else
    echo "Failed to retrieve the resource id of the [$serviceBusQueueName] service bus queue."
    exit
  fi

  # Check if the Event Grid subscription exists
  az eventgrid event-subscription show \
    --name $eventGridSubscriptionName \
    --source-resource-id $resourceId &>/dev/null

  if [[ $? != 0 ]]; then
    echo "No [$eventGridSubscriptionName] Event Grid subscription actually exists for [$subscriptionName] subscription events"
    echo "Creating [$eventGridSubscriptionName] Event Grid subscription for [$subscriptionName] subscription events..."
    # Create Event Grid subscription
    az eventgrid event-subscription create \
      --endpoint-type $endpointType \
      --endpoint $serviceBusId \
      --deadletter-endpoint ${storageAccountId}/blobServices/default/containers/$containerName \
      --name $eventGridSubscriptionName \
      --subject-ends-with $subjectEndsWith \
      --source-resource-id $resourceId 1>/dev/null

    # Create the Event Grid subscription
    if [[ $? == 0 ]]; then
      echo "[$eventGridSubscriptionName] Event Grid subscription successfully created in the [$subscriptionName] subscription"
    else
      echo "Failed to create [$eventGridSubscriptionName] Event Grid subscription in the [$subscriptionName] subscription"
      exit
    fi
  else
    echo "[$eventGridSubscriptionName] Event Grid subscription already exists in the [$subscriptionName] subscription"
  fi
done
