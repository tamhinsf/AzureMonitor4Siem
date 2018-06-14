#!/bin/sh

# store year month date time as a variable
# append it to resources to semi-ensure unique names where needed
DATE_TIME=`date +'%Y%m%d%H%M'`

# Change these values to accomodate your environment
# No checks of name space compliance, collisions, or the like takes place
# This script will fail if any of the above occur
AZ_RESOURCE_GROUP=mysiemrg
AZ_REGION=westus2
AZ_STORAGE_ACCOUNT=mysiemsa$DATE_TIME
AZ_STORAGE_ACCOUNT_CONTAINER=mysiemsacontainer
AZ_STORAGE_ACCOUNT_SAS_EXPIRY=2030-01-01
AZ_EVENTHUB_NAMESPACE=mysiemehns$DATE_TIME

# Save the Storage Account SAS And Event Hub Connection string to a variable
AZ_STORAGE_ACCOUNT_SAS=
AZ_EVENTHUB_CONNECTION_STRING=

# Use this variable to store where log files get placed during runtime
AZ_MONITOR_LOG_FILE_PATH=

# Start!

echo ""
echo "Welcome to the Azure Monitor starter kit!"
echo ""

read -p "Use cached credentials from a previous az login? " -n 1 -r
echo   
if [[ $REPLY =~ ^[Nn]$ ]]
then
    az login
fi

# Get the ID of the Azure Subscription 
AZ_SUBSCRIPTION_ID=`az account show --query id | sed 's/^"\(.*\)"$/\1/'`

# Confirm deletion of any existing resource group or monitor configuration of the same name
read -p "Delete any existing Azure Resouce Group ($AZ_RESOURCE_GROUP), Monitor Configuration, and azureSettings.json? " -n 1 -r
echo   
if [[ $REPLY =~ ^[Yy]$ ]]
then
    az monitor log-profiles delete --name "default"
    az group delete -y -n $AZ_RESOURCE_GROUP
    rm azureSettings.json
fi

# Setup the Resource Group in the specified region
az group create -n $AZ_RESOURCE_GROUP -l $AZ_REGION

# Setup the Blob Storage account and generate a SAS
az storage account create --name $AZ_STORAGE_ACCOUNT --resource-group $AZ_RESOURCE_GROUP --kind BlobStorage --location $AZ_REGION --access-tier hot
az storage account show-connection-string --name $AZ_STORAGE_ACCOUNT --resource-group $AZ_RESOURCE_GROUP
az storage container create --account-name $AZ_STORAGE_ACCOUNT --name $AZ_STORAGE_ACCOUNT_CONTAINER
AZ_STORAGE_ACCOUNT_SAS=`az storage account generate-sas --account-name $AZ_STORAGE_ACCOUNT --services b --resource-types sco --permissions acdlrw --https-only --expiry $AZ_STORAGE_ACCOUNT_SAS_EXPIRY | sed 's/^"\(.*\)"$/\1/' `

# Setup the Event Hub Name Space
az eventhubs namespace create --resource-group $AZ_RESOURCE_GROUP --name $AZ_EVENTHUB_NAMESPACE --sku Standard --capacity 1 --location $AZ_REGION

# Setup Azure Monitor to use the Event Hub Namespace just created
# This process will setup an Event Hub within the Namespace called insights-operational-logs
az monitor log-profiles create --name "default" --location null --locations "global" --categories "Delete" "Write" "Action"  --enabled true --days 7 --service-bus-rule-id "/subscriptions/$AZ_SUBSCRIPTION_ID/resourceGroups/$AZ_RESOURCE_GROUP/providers/Microsoft.EventHub/namespaces/$AZ_EVENTHUB_NAMESPACE/authorizationrules/RootManageSharedAccessKey"

# The above process "completes" although the Event Hub isn't yet created.
# We'll poll the Event Hub Namespace to determine when the Event Hub has been created
AZ_EVENTHUB_CREATION_STATUS=
while [ -z "$AZ_EVENTHUB_CREATION_STATUS" ]
do
    echo "Waiting for Event Hub Creation to complete"
    sleep 30
    AZ_EVENTHUB_CREATION_STATUS=`az eventhubs eventhub list --resource-group $AZ_RESOURCE_GROUP --namespace-name $AZ_EVENTHUB_NAMESPACE -o tsv | grep insights-operational-logs`
done

# Now, create a Shared Access Signature that provides limited access to the Event Hub
# i.e. don't use the Event Hub Namespace master keys
az eventhubs eventhub authorization-rule create --namespace-name $AZ_EVENTHUB_NAMESPACE --resource-group $AZ_RESOURCE_GROUP --eventhub-name insights-operational-logs --rights Listen --name azureMonitor
AZ_EVENTHUB_CONNECTION_STRING=`az eventhubs eventhub authorization-rule keys list --namespace-name $AZ_EVENTHUB_NAMESPACE --resource-group $AZ_RESOURCE_GROUP --eventhub-name insights-operational-logs --name azureMonitor --query primaryConnectionString | sed 's/^"\(.*\)"$/\1/' `

# Echo Azure settings for the user to see
echo "Storage Account Name is" $AZ_STORAGE_ACCOUNT
echo "Storage Account Container Name is" $AZ_STORAGE_ACCOUNT_CONTAINER
echo "Storage Shared Access Signature is" $AZ_STORAGE_ACCOUNT_SAS
echo "Event Hub Name is insights-operational-logs"
echo "Event Hub Connection String is" $AZ_EVENTHUB_CONNECTION_STRING

echo "Where do you want the Azure Monitor log files to be stored?"
echo "If you don't know, just press enter.  We'll create a temporary directory each time you run the app."
read -p "Path: " PATH_ENTERED
if [[ ! -z $PATH_ENTERED ]]
then
    AZ_MONITOR_LOG_FILE_PATH=$PATH_ENTERED
    echo "Azure Monitor Log file path set to" $AZ_MONITOR_LOG_FILE_PATH
else
    echo "No path entered. We'll create a temporary directory each time you run the app."
fi

# Put Azure settings into a JSON file so our .NET app can use them
printf '{\n "az_storage_account":"%s",\n "az_storage_account_container":"%s",\n "az_storage_account_sas":"%s", \n "az_event_hub_connection_string":"%s", \n "az_event_hub_name" : "%s", \n "az_local_logs_dir" : "%s" \n }\n' "$AZ_STORAGE_ACCOUNT" "$AZ_STORAGE_ACCOUNT_CONTAINER" "$AZ_STORAGE_ACCOUNT_SAS" "$AZ_EVENTHUB_CONNECTION_STRING" "insights-operational-logs" "$AZ_MONITOR_LOG_FILE_PATH" > azureSettings.json

echo "Setup complete. You'll now need to build and run the application: dotnet clean;dotnet build;dotnet run"