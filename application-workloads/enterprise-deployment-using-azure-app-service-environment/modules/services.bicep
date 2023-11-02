@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where the gateway will be connected.')
param vnetName string

@description('The name for the sql server admin user.')
param sqlAdminUserName string

@description('The password for the sql server admin user.')
@secure()
param sqlAdminPassword string

@description('The SID for the AAD user to be the AD admin for the database server')
param sqlAadAdminSid string

@description('True for high availability deployments, False otherwise.')
param zoneRedundant bool = false

@description('Comma separated subnet names that can access the services.')
param allowedSubnetNames string

var cosmosName = 'votingcosmos-${uniqueString(resourceGroup().id)}'
var cosmosDatabaseName = 'cacheDB'
var cosmosContainerName = 'cacheContainer'
var cosmosPartitionKeyPaths = [
  '/MessageType'
]
var sqlServerName = 'sqlserver-azinsider'
var sqlDatabaseName = 'voting'
var serviceBusName = 'votingservicebus'
var serviceBusQueueName = 'votingqueue'
var resourcesStorageAccountName = toLower('resources${uniqueString(resourceGroup().id)}')
var resourcesContainerName = 'rscontainer'
var keyVaultName = 'kv-nb${uniqueString(resourceGroup().id, deployment().name)}'
var allowedSubnetNamesArray = split(allowedSubnetNames, 'ase-subnet, services-subnet')
 
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: cosmosName
  location: location
  tags: {
    defaultExperience: 'Core (SQL)'
  }
  kind: 'GlobalDocumentDB'
  properties: {
    //ipRangeFilter: ''
    publicNetworkAccess: 'Disabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: true
    isVirtualNetworkFilterEnabled: true    
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: zoneRedundant
      }
    ]
    capabilities: []
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: cosmos
  name: cosmosDatabaseName
  properties: {
    resource: {
      id: cosmosDatabaseName
    }
    options: {
      throughput: 400
    }
  }
}

resource cosmosDatabaseContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: cosmosDatabase
  name: cosmosContainerName
  properties: {
    options: {
      throughput: 400
    }
    resource: {
      id: cosmosContainerName
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: cosmosPartitionKeyPaths
        kind: 'Hash'
      }
    }
  }
}
 
resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUserName
    publicNetworkAccess: 'Disabled'
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: (zoneRedundant ? 'BC_Gen5' : 'GP_Gen5')
    tier: (zoneRedundant ? 'BusinessCritical' : 'GeneralPurpose')
    family: 'Gen5'
    capacity: 2
  }
  //kind: 'v12.0,user,vcore'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
    zoneRedundant: zoneRedundant
  }
}


resource sqlServerActiveDirectory 'Microsoft.Sql/servers/administrators@2022-02-01-preview' = {
  parent: sqlServer
  name: 'activeDirectory'
  //location: location
  properties: {
    administratorType: 'ActiveDirectory'
    login: 'ADMIN'
    sid: sqlAadAdminSid
    tenantId: subscription().tenantId
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: []
    publicNetworkAccess: 'disabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId    
  }
}

resource keyVaultCosmosKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'CosmosKey'
  properties: {
    value: cosmos.listKeys().primaryMasterKey 
  }
}

resource keyVaultServiceBusListenerConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'ServiceBusListenerConnectionString'
  properties: {
    value: 'Endpoint=sb://${serviceBusName}.servicebus.windows.net/;SharedAccessKeyName=${serviceBusListenerSharedAccessKey.name};SharedAccessKey=${listKeys(serviceBusListenerSharedAccessKey.id, '2021-11-01').primaryKey}'
  }
}

resource keyVaultServiceBusSenderConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'ServiceBusSenderConnectionString'
  properties: {
    value: 'Endpoint=sb://${serviceBusName}.servicebus.windows.net/;SharedAccessKeyName=${serviceBusSenderSharedAccessKey.name};SharedAccessKey=${listKeys(serviceBusSenderSharedAccessKey.id, '2021-11-01').primaryKey}'
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 1
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    zoneRedundant: zoneRedundant
  }
}

resource serviceBusListenerSharedAccessKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: serviceBus
  name: 'ListenerSharedAccessKey'
  //location: location
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource serviceBusSenderSharedAccessKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: serviceBus
  name: 'SenderSharedAccessKey'
  //location: location
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  parent: serviceBus
  name: serviceBusQueueName
  //location: location
  properties: {
    lockDuration: 'PT1M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource resourcesStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: resourcesStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: (zoneRedundant ? 'Standard_ZRS' : 'Standard_LRS')    
    //tier: 'Standard'
  }
  properties: {
    allowBlobPublicAccess: true
    accessTier: 'Hot'
  }
}


resource resourcesStorageAccountDefaultResourcesContainerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${resourcesStorageAccountName}/default/${resourcesContainerName}'
  properties: {
    publicAccess: 'Blob'
  }
  dependsOn: [
    resourcesStorageAccount
  ]
}

output cosmosDbName string = cosmosName
output sqlServerName string = sqlServerName
output sqlDatabaseName string = sqlDatabaseName
output resourcesStorageAccountName string = resourcesStorageAccountName
output resourcesContainerName string = resourcesContainerName
output keyVaultName string = keyVaultName
output serviceBusName string = serviceBusName
