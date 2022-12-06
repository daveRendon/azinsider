@description('The email address of the owner of the service')
@minLength(1)
param apiManagementPublisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param apiManagementPublisherName string

@description('The pricing tier of this API Management service')
@allowed([
  'Developer'
  'Premium'
])
param apiManagementSku string = 'Premium'

@description('The instance size of this API Management service.')
param apiManagementSkuCount int = 1

@description('Select the SKU for your workspace')
@allowed([
  'pergb2018'
  'Premium'
])
param omsSku string = 'pergb2018'

@description('Location for all resources.')
param location string = resourceGroup().location

var apiManagementServiceName = 'apiservice-azinsdr'
var omsWorkspaceName = 'azinsdr-workspace'

resource apiManagementService 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: apiManagementSku
    capacity: apiManagementSkuCount
  }
  identity: {
    type: 'SystemAssigned'
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

resource apiManagementServiceName_Microsoft_Insights_service 'Microsoft.ApiManagement/service/providers/diagnosticSettings@2021-05-01-preview' = {
  name: '${apiManagementServiceName}/Microsoft.Insights/service'
  properties: {
    workspaceId: omsWorkspace.id
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
    ]
  }
  dependsOn: [
    apiManagementService

  ]
}
