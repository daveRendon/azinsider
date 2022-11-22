@description('The name of the Event Grid custom topic.')
param topicName string = 'topic${uniqueString(resourceGroup().id)}'

@description('The name of the Event Grid custom topic\'s subscription.')
param subscriptionName string = 'subSendToEventHubs'

@description('The name of the Event Hubs namespace.')
param eventHubNamespace string = 'namespace${uniqueString(resourceGroup().id)}'

@description('The name of the event hub.')
param eventHubName string = 'eventhub'

@description('The location in which the Event Grid resources should be deployed.')
param location string = resourceGroup().location

resource topic 'Microsoft.EventGrid/topics@2020-06-01' = {
  name: topicName
  location: location
}

resource eventHubNamespace_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: eventHubNamespace
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    isAutoInflateEnabled: true
    maximumThroughputUnits: 7
  }
}

resource eventHubNamespace_eventHub 'Microsoft.EventHub/namespaces/EventHubs@2017-04-01' = {
  parent: eventHubNamespace_resource
  name: eventHubName
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
  }
}

resource subscription 'Microsoft.EventGrid/eventSubscriptions@2020-06-01' = {
  scope: topic
  name: subscriptionName
  properties: {
    destination: {
      endpointType: 'EventHub'
      properties: {
        resourceId: eventHubNamespace_eventHub.id
      }
    }
    filter: {
      isSubjectCaseSensitive: false
    }
  }
}

output endpoint string = topic.properties.endpoint
