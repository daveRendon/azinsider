@description('The email address of the owner of the service')
@minLength(1)
param apiManagementPublisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param apiManagementPublisherName string

@description('The pricing tier of this API Management service')
@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param apiManagementSku string = 'Developer'

@description('The instance size of this API Management service.')
param apiManagementSkuCount int = 1

@description('Select the SKU for your workspace')
@allowed([
  'pergb2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
param omsSku string = 'PerNode'

@description('Location for all resources.')
param location string = resourceGroup().location

var apiManagementServiceName = 'apiservice${uniqueString(resourceGroup().id)}'
var omsWorkspaceName = 'omsworkspace${uniqueString(resourceGroup().id)}'

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: apiManagementSku
    capacity: apiManagementSkuCount
  }
  properties: {
    publisherEmail: apiManagementPublisherEmail
    publisherName: apiManagementPublisherName
  }
}

resource omsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: omsWorkspaceName
  location: location
  properties: {
    sku: {
      name: omsSku
    }
  }
}

resource apiManagementServiceName_Microsoft_Insights_service 'Microsoft.ApiManagement/service/diagnostics@2021-12-01-preview' = {
  name: '${apiManagementServiceName}Microsoft.Insights/service'
  properties: {
    alwaysLog: 'allErrors'
    loggerId: omsWorkspace.id
  }
  dependsOn: [
    apiManagementService

  ]
}
