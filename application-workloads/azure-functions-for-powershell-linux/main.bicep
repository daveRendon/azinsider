param functionAppName string
param location string
param hostingPlanName string
param alwaysOn bool
param use32BitWorkerProcess bool
param ftpsState string
param storageAccountName string
param linuxFxVersion string
param sku string
param skuCode string

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

var applicationInsightsName = functionAppName

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
    zoneRedundant: true
  }
  sku: {
    tier: sku
    name: skuCode
  }
}

resource applicationInsights 'microsoft.insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', applicationInsightsName)}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  kind: 'functionapp,linux'
  location: location
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('microsoft.insights/components/azinsiderfun', '2015-05-01').InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: reference('microsoft.insights/components/azinsiderfun', '2015-05-01').ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccount.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      use32BitWorkerProcess: use32BitWorkerProcess
      ftpsState: ftpsState
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
    }
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    httpsOnly: true
  }
  dependsOn: [
    applicationInsights
  ]
}








