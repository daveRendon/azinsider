@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where redis will be connected.')
param vnetName string

@description('The ip address prefix REDIS will use.')
param redisSubnetAddressPrefix string

@description('The ASE name where to host the applications')
param aseName string = 'ase-azinsider'

@description('DNS suffix where the app will be deployed')
param aseDnsSuffix string = 'ase-azinsider'

@description('The name of the key vault name')
param keyVaultName string

@description('The cosmos DB name')
param cosmosDbName string

@description('The name for the sql server')
param sqlServerName string

@description('The name for the sql database')
param sqlDatabaseName string

@description('The name for the log analytics workspace')
param logAnalyticsWorkspace string = '${uniqueString(resourceGroup().id)}la'

@description('The availability zone to deploy. Valid values are: 1, 2 or 3. Use empty to not use zones.')
param zoneRedundant bool = false

var redisName = 'redis-${uniqueString(resourceGroup().id)}'
var redisSubnetName = 'redis-subnet'
var redisSubnetId = redisSubnet.id
var redisNSGName = 'redis-nsg'
var redisSecretName = 'RedisConnectionString'
var cosmosKeySecretName = 'CosmosKey'
var serviceBusListenerConnectionStringSecretName = 'ServiceBusListenerConnectionString'
var serviceBusSenderConnectionStringSecretName = 'ServiceBusSenderConnectionString'
var votingApiName = 'votingapiapp-azinsider'
var votingWebName = 'votingwebapp-azinsider'
var testWebName = 'testwebapp-azinsider'
var votingFunctionName = 'votingfuncapp-${uniqueString(resourceGroup().id)}azinsider'
var votingApiPlanName = '${votingApiName}-plan'
var votingWebPlanName = '${votingWebName}-plan'
var testWebPlanName = '${testWebName}-plan'
var votingFunctionPlanName = '${votingFunctionName}-plan'
var aseId = resourceId('Microsoft.Web/hostingEnvironments', 'ase-azinsider')

resource redisNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: redisNSGName
  location: location
  tags: {
    displayName: redisNSGName
  }
  properties: {
    securityRules: [
      {
        name: 'REDIS-inbound-vnet'
        properties: {
          description: 'Client communication inside vnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '6379'
            '6380'
            '13000-13999'
            '15000-15999'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: redisSubnetAddressPrefix
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'REDIS-inbound-loadbalancer'
        properties: {
          description: 'Allow communication from Load Balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: redisSubnetAddressPrefix
          access: 'Allow'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'REDIS-inbound-allow_internal-communication'
        properties: {
          description: 'Internal communications for Redis'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '6379'
            '6380'
            '8443'
            '10221-10231'
            '20226'
          ]
          sourceAddressPrefix: redisSubnetAddressPrefix
          destinationAddressPrefix: redisSubnetAddressPrefix
          access: 'Allow'
          priority: 202
          direction: 'Inbound'
        }
      }
      {
        name: 'REDIS-outbound-allow_storage'
        properties: {
          description: 'Redis dependencies on Azure Storage/PKI (Internet)'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: redisSubnetAddressPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
        }
      }
      {
        name: 'REDIS-outbound-allow_DNS'
        properties: {
          description: 'Redis dependencies on DNS (Internet/VNet)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 201
          direction: 'Outbound'
        }
      }
      {
        name: 'REDIS-outbound-allow_ports-within-subnet'
        properties: {
          description: 'Internal communications for Redis'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: redisSubnetAddressPrefix
          destinationAddressPrefix: redisSubnetAddressPrefix
          access: 'Allow'
          priority: 202
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource redisSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${vnetName}/${redisSubnetName}'
  //location: location
  properties: {
    addressPrefix: redisSubnetAddressPrefix
    networkSecurityGroup: {
      id: redisNSG.id
    }
  }
}

resource redis 'Microsoft.Cache/Redis@2022-06-01' = {
  name: redisName
  location: location
  zones: (zoneRedundant ? ['1','2','3'] : null)
  properties: {
    sku: {
      name: 'Premium'
      family: 'P'
      capacity: 3
    }
    enableNonSslPort: false
    subnetId: redisSubnetId
  }
}


resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}


resource keyVaultRedisSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: redisSecretName
  properties: {
    value: '${redisName}.redis.cache.windows.net:6380,abortConnect=false,ssl=true,password=${listKeys(redis.id, '2015-08-01').primaryKey}'
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspace
  location: location  
}


resource votingFunctionAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: votingFunctionName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'AppServiceEnablementCreate'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingApi 'Microsoft.Insights/components@2020-02-02' = {
  name: votingApiName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingWeb 'Microsoft.Insights/components@2020-02-02' = {
  name: votingWebName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource testWeb 'Microsoft.Insights/components@2020-02-02' = {
  name: testWebName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingFunctionPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: votingFunctionPlanName
  location: location
  sku: {
    name: 'I1V2'
    tier: 'IsolatedV2'
  }
  //kind: 'functionapp'
  properties: {
    //name: votingFunctionPlanName_var
    perSiteScaling: false
    reserved: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    //hostingEnvironment: aseName
    hostingEnvironmentProfile: {
      id:aseId
    }
  }
}

resource votingApiPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: votingApiPlanName
  location: location
  sku: {
    name: 'I1V2'
    tier: 'IsolatedV2'
  }
  kind: 'app'
  properties: {
    //name: votingApiPlanName_var
    perSiteScaling: false
    reserved: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    //hostingEnvironment: aseName
    hostingEnvironmentProfile: {
      id:aseId
    }
  }
}

resource votingWebPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: votingWebPlanName
  location: location
  sku: {
    name: 'I1V2'
    tier: 'IsolatedV2'
  }
  kind: 'app'
  properties: {
    //name: votingWebPlanName_var
    perSiteScaling: false
    reserved: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    //hostingEnvironment: aseName
    hostingEnvironmentProfile: {
      id:aseId
    }
  }
}

resource testWebPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: testWebPlanName
  location: location
  sku: {
    name: 'I1V2'
    tier: 'IsolatedV2'
  }
  kind: 'app'
  properties: {
    //name: testWebPlanName_var
    perSiteScaling: false
    reserved: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    //hostingEnvironment: aseName
    hostingEnvironmentProfile: {
      id:aseId
    }
  }
}

resource votingFunction 'Microsoft.Web/sites@2022-03-01' = {
  name: votingFunctionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    //name: votingFunctionName_var
    hostingEnvironmentProfile: {
      id:aseId
    }
    serverFarmId: votingFunctionPlan.id
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(votingFunctionAppInsights.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${reference(votingFunctionAppInsights.id, '2020-02-02').InstrumentationKey}'
        }
        {
          name: 'SERVICEBUS_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${serviceBusListenerConnectionStringSecretName})'
        }
        {
          name: 'sqldb_connection'
          value: 'Server=${sqlServerName}.database.windows.net,1433;Database=${sqlDatabaseName};'
        }
      ]
    }
  }
}

resource votingApiApp 'Microsoft.Web/sites@2022-03-01' = {
  name: votingApiName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    //name: votingApiName_var
    hostingEnvironmentProfile: {
      id:aseId
    }
    serverFarmId: votingApiPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(votingApi.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(votingApi.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ConnectionStrings:SqlDbConnection'
          value: 'Server=${sqlServerName}.database.windows.net,1433;Database=${sqlDatabaseName};'
        }
      ]
    }
  }
}

resource votingWebApp 'Microsoft.Web/sites@2022-03-01' = {
  name: votingWebName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostingEnvironmentProfile: {
      id:aseId
    }
    serverFarmId: votingWebPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(votingWeb.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ConnectionStrings:sbConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${serviceBusSenderConnectionStringSecretName})'
          
        }
        {
          name: 'ConnectionStrings:VotingDataAPIBaseUri'
          value: 'https://${votingApiApp.properties.hostNames[0]}'
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(votingWeb.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ConnectionStrings:RedisConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${keyVaultRedisSecret.name})'
        }
        {
          name: 'ConnectionStrings:queueName'
          value: 'votingqueue'
        }
        {
          name: 'ConnectionStrings:CosmosUri'
          value: 'https://${cosmosDbName}.documents.azure.com:443/'
        }
        {
          name: 'ConnectionStrings:CosmosKey'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${cosmosKeySecretName})'
        }
      ]
    }
  }
}

resource testWebApp 'Microsoft.Web/sites@2022-03-01' = {
  name: testWebName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    //name: testWebName_var
    hostingEnvironmentProfile: {
      id:aseId
    }
    serverFarmId: testWebPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(testWeb.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(testWeb.id, '2020-02-02').InstrumentationKey
        }
      ]
    }
  }
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: votingFunction.identity.principalId
        permissions: {
          secrets: ['get','list']
          keys: ['get','list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: votingWebApp.identity.principalId
        permissions: {
          secrets: ['get','list']
          keys: ['get','list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: votingApiApp.identity.principalId
        permissions: {
          secrets: ['get','list']
          keys: ['get','list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: testWebApp.identity.principalId
        permissions: {
          secrets: ['get','list']
          keys: ['get','list']
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

output redisName string = redisName
output redisSubnetId string = redisSubnetId
output redisSubnetName string = redisSubnetName
output votingWebName string = votingWebName
output testWebName string = testWebName
output votingAppUrl string = '${votingWebName}.${aseDnsSuffix}'
output testAppUrl string = '${testWebName}.${aseDnsSuffix}'
output votingApiName string = votingApiName
output votingFunctionName string = votingFunctionName
output votingWebAppIdentityPrincipalId string = reference('Microsoft.Web/sites/${votingWebName}', '2022-03-01', 'Full').identity.principalId
output votingApiIdentityPrincipalId string = reference('Microsoft.Web/sites/${votingApiName}', '2022-03-01', 'Full').identity.principalId
output votingCounterFunctionIdentityPrincipalId string = reference('Microsoft.Web/sites/${votingFunctionName}', '2022-03-01', 'Full').identity.principalId
output votingAppURLstring string = votingWebApp.properties.hostNames[0]
