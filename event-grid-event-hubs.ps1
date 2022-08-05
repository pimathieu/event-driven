# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# 
#This it to route custom events to Azure Event Hubs with Azure CLI and Event Grid
    ## Enable an Event Grid resource provider
    ## Create a custom topic
    ## Create event hub
    ## Create a message endpoint
    ## Subscribe to a custom topic
    ## Send an events to a custom topic

#Let's define some bash variables to work with during the process
$rNum= Get-Random
$myLocation="eastus"
$myTopicName="azure-egtopic-${rNum}"
$mySiteName="azure-egsite-${rNum}"
$mySiteURL="https://${mySiteName}.azurewebsites.net"
$myEvHubNameSpace = "azureevhubnp${rNum}"
$myHubName="demoeventhub"
$myResourcegroup = "azure-evgrid-evhubs-grp"
$mysubViewer = "azureViewerSub"

#Create a resource group for the all our resources 
az group create --name $myResourcegroup --location $myLocation

#Let's enable the Event Grid reource provider, if the subcription has not previously used Event Grid. Second query may be run first to know if already registered.
az provider register --namespace Microsoft.EventGrid
az provider show --namespace Microsoft.EventGrid --query "registrationState"


#Create a custom topic

az eventgrid topic create --name $myTopicName    --location $myLocation  --resource-group $myResourcegroup

#Create event hub
az eventhubs namespace create --name $myEvHubNameSpace --resource-group $myResourcegroup
az eventhubs eventhub create --name $myHubName --namespace-name $myEvHubNameSpace --resource-group $myResourcegroup

#Subscribe to a custom topic
$hubid=$(az eventhubs eventhub show --name $myHubName --namespace-name $myEvHubNameSpace --resource-group $myResourcegroup --query id --output tsv)
$topicid=$(az eventgrid topic show --name $myTopicName -g $myResourcegroup --query id --output tsv)

az eventgrid event-subscription create  --source-resource-id $topicid  --name $mysubViewer  --endpoint-type eventhub  --endpoint $hubid


#Send an events to your custom topic
$endpoint=$(az eventgrid topic show --name $myTopicName -g $myResourcegroup --query "endpoint" --output tsv)
$key=$(az eventgrid topic key list --name $myTopicName -g $myResourcegroup --query "key1" --output tsv)


for($i=1; $i -le 10; $i++){
    
    $rNum= Get-Random
    Write-Host $rNum
    $now = Get-Date -UFormat "%A %m/%d/%Y %R %Z"
    $body ='[{
            "id": "' + $rNum + '",
            "eventType": "recordInserted",
            "subject": "myapp/vehicles/motorcycles",
            "eventTime": "'+ $now +'",
            "data": {
                "key1": "value1-'+$rNum+'",
                "key2": "value2-'+$rNum+'"
            },
            "dataVersion": "1.0"
            }]'

    Invoke-WebRequest -Uri $endpoint -Method POST -Body $body -Headers @{"aeg-sas-key" = $key}
}


#Cleanup
#az group delete --name azure-evgrid-evhubs-grp --no-wait