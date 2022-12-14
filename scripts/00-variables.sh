# Variables for the Event Grid demo

# Location
location="WestEurope"

# Resource group name
resourceGroupName="MiaEventGridRG"

# Event Grid Topic
topicName="MiaEventGrid"
publicNetworkAccess="enabled"
tags="service=EventGrid workload=$topicName"

# Subscription endpoint type
endpointType="servicebusqueue"

# Sku of the service bus namespace
serviceBusSku="Standard"

# Name of the service bus queue
serviceBusQueueName="events"

# Name of the deadletter storage account
storageAccountName="deadletterstore"

# Name of the deadletter container
containerName="deadletter"

# Tenants
tenants=("Fabrikam" "Contoso" "Acme")

# Events
id=1000
eventType="recordInserted"

# SubscriptionId of the current subscription
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)