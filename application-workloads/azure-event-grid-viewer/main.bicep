param webAppPrefix string = 'azinsidr' // Generate unique String for web app name
param sku string = 'F1' // The SKU of App Service Plan
param location string = resourceGroup().location // Location for all resources
var appServicePlanName = toLower('AppServicePlan-${webAppPrefix}')
var webAppName = toLower('wapp-${webAppPrefix}')

@description('The name of the Event Grid custom topic.')
param eventGridTopicName string = '${webAppPrefix}-topic'

@description('The name of the Event Grid custom topic\'s subscription.')
param eventGridSubscriptionName string = '${webAppPrefix}-sub'

@description('The webhook URL to send the subscription events to. This URL must be valid and must be prepared to accept the Event Grid webhook URL challenge request.')
param eventGridSubscriptionUrl string = 'https://wapp-${webAppPrefix}.azurewebsites.net/api/updates'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
  kind: 'linux'
}

resource webApp 'Microsoft.Web/sites@2021-01-01' = {
  name: webAppName
  location: location
  tags: {}
  properties: {
    siteConfig: {
      appSettings: []
      linuxFxVersion: 'DOCKER|microsoftlearning/azure-event-grid-viewer:latest'
    }
    serverFarmId: appServicePlan.id
  }
}

resource eventGridTopic 'Microsoft.EventGrid/topics@2020-06-01' = {
  name: eventGridTopicName
  location: location
}

resource eventGridSubscription 'Microsoft.EventGrid/eventSubscriptions@2020-06-01' = {
  name: eventGridSubscriptionName
  scope: eventGridTopic
  dependsOn:[
    webApp
  ]
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: eventGridSubscriptionUrl
      }
    }
  }
}


