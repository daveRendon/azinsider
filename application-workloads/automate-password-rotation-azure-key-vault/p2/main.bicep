@description('SQL server name with password to rotate.')
param sqlServerName string = 'akvrotation-sql'

param location string = 'eastus'

@description('Key Vault name where password is stored.')
param keyVaultName string = 'akvrotation-kv'

@description('The name of the function app that you wish to create.')
param functionAppName string = 'akvrotation-fnapp'

@description('The name of the secret where sql password is stored.')
param secretName string = 'sqlPassword'

@description('The URL for the GitHub repository that contains the project to deploy.')
param repoURL string = 'https://github.com/daveRendon/KeyVault-Rotation.git'

var functionStorageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'
var eventSubscriptionName = '${keyVaultName}-${secretName}-${functionAppName}'

resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: functionStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource functionApp 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: concat(functionAppName)
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }

}

resource Microsoft_Web_sites_functionApp 'Microsoft.Web/sites@2018-11-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: functionApp.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};AccountKey=${listKeys(functionStorageAccount.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorageAccount.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(microsoft_insights_components_functionApp.id, '2018-05-01-preview').InstrumentationKey
        }
      ]
    }
  }
}

resource functionAppName_web 'Microsoft.Web/sites/sourcecontrols@2018-11-01' = {
  name: '${functionAppName}/web'
  properties: {
    repoUrl: repoURL
    branch: 'master'
    isManualIntegration: true
  }
  dependsOn: [
    Microsoft_Web_sites_functionApp
  ]
}

resource microsoft_insights_components_functionApp 'microsoft.insights/components@2018-05-01-preview' = {
  name: functionAppName
  location: location
  kind: 'web'
  properties: {
    Application_Type: functionAppName
    Request_Source: 'IbizaWebAppExtensionCreate'
  }
}

resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2018-02-14' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(Microsoft_Web_sites_functionApp.id, '2019-08-01', 'Full').identity.principalId
        permissions: {
          keys: []
          secrets: [
            'Get'
            'List'
            'Set'
          ]
          certificates: []
        }
      }
    ]
  }
}

resource keyVaultName_Microsoft_EventGrid_eventSubscription 'Microsoft.KeyVault/vaults/providers/eventSubscriptions@2020-01-01-preview' = {
  name: '${keyVaultName}/Microsoft.EventGrid/${eventSubscriptionName}'
  location: location
  properties: {
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
        resourceId: '${Microsoft_Web_sites_functionApp.id}/functions/AKVSQLRotation'
      }
    }
    filter: {
      subjectBeginsWith: secretName
      subjectEndsWith: secretName
      includedEventTypes: [
        'Microsoft.KeyVault.SecretNearExpiry'
      ]
    }
  }
  dependsOn: [
    functionAppName_web
  ]
}
