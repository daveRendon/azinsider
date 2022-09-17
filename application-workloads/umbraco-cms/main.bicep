@description('The name of the action group.')
param actionGroupName string

@description('The short name of the action group.')
param actionGroupShortName string

@description('Name of azure web app.')
param appName string

@description('SQL Azure DB Server name')
param dbServerName string

@description('SQL Azure DB administrator  user login')
param dbAdministratorLogin string

@description('Database admin user password')
@secure()
param dbAdministratorLoginPassword string

@description('Database Name')
param dbName string

@description('Non-admin Database User. Must be Unique')
param nonAdminDatabaseUsername string

@description('Non-admin Database User password')
@secure()
param nonAdminDatabasePassword string

@description('Storage Account Type : Standard-LRS, Standard-GRS,Standard-RAGRS,Standard-ZRS')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Redis Cache Name')
param redisCacheName string

@description('Redis Cache appServiceTier - Basic , Standard')
@allowed([
  'Basic'
  'Standard'
])
param redisCacheServiceTier string = 'Standard'

@description('A list of strings representing the email addresses to send alerts to.')
param emails array

@description('Location for all resources.')
param location string = resourceGroup().location
param packageUri string

var storageAccountName_var = '${uniqueString(resourceGroup().id)}standardsa'
var umbracoAdminWebAppName_var = '${appName}adminapp'
var appServicePlanName_var = '${appName}serviceplan'

resource actionGroupName_resource 'microsoft.insights/actionGroups@2019-06-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: [
      {
        name: 'test'
        emailAddress: emails[0]
        useCommonAlertSchema: true
      }
    ]
  }
}

resource redisCacheName_resource 'Microsoft.Cache/redis@2022-05-01' = {
  name: redisCacheName
  location: location
  properties: {
    sku: {
      name: redisCacheServiceTier
      family: 'C'
      capacity: 0
    }
    redisVersion: 'latest'
    enableNonSslPort: true
  }
}

resource dbServerName_resource 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: dbServerName
  location: location
  properties: {
    administratorLogin: dbAdministratorLogin
    administratorLoginPassword: dbAdministratorLoginPassword
    version: '12.0'
  }
}

resource dbServerName_dbName 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  parent: dbServerName_resource
  name: dbName
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    recoveryServicesRecoveryPointId: 'F1173C43-91BD-4AAA-973C-54E79E15235B'
  }
}

resource dbServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2021-02-01-preview' = {
  parent: dbServerName_resource
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}


resource appServicePlanName 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName_var
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }
}


resource appName_resource 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  tags: {
    'hidden-related:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}': 'empty'
  }
  properties: {
    serverFarmId: appServicePlanName.id
  }
}

resource appName_MSDeploy 'Microsoft.Web/sites/extensions@2021-02-01' = {
  parent: appName_resource
  name: 'MSDeploy'
  properties: {
    packageUri: packageUri
    dbType: 'SQL'
    connectionString: 'Data Source=tcp:${dbServerName_resource.properties.fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
    setParameters: {
      'Application Path': appName
      'Database Server': dbServerName_resource.properties.fullyQualifiedDomainName
      'Database Name': dbName
      'Database Username': nonAdminDatabaseUsername
      'Database Password': nonAdminDatabasePassword
      'Database Administrator': dbAdministratorLogin
      'Database Administrator Password': dbAdministratorLoginPassword
      azurestoragerootUrl: 'https://${storageAccountName_var}.blob.${environment().suffixes.storage}'
      azurestoragecontainerName: 'media'
      azurestorageconnectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName_var, '2021-04-01').keys[0].value}'
      rediscachehost: '${redisCacheName}.redis.cache.windows.net'
      rediscacheport: '6379'
      rediscacheaccessKey: listKeys(redisCacheName_resource.id, '2020-06-01').primaryKey
      azurestoragecacheControl: '*|public, max-age=31536000;js|no-cache'
    }
  }
  dependsOn: [

    appName_web
    dbServerName_dbName
    storageAccountName
  ]
}

resource appName_connectionstrings 'Microsoft.Web/Sites/config@2020-12-01' = {
  parent: appName_resource
  name: 'connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Data Source=tcp:${dbServerName_resource.properties.fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
  dependsOn: [

    dbServerName_dbName
    appName_MSDeploy
  ]
}

resource appName_web 'Microsoft.Web/Sites/config@2020-12-01' = {
  parent: appName_resource
  name: 'web'
  properties: {
    phpVersion: 'off'
    netFrameworkVersion: 'v4.5'
    use32BitWorkerProcess: true
    webSocketsEnabled: true
    alwaysOn: true
    httpLoggingEnabled: true
    logsDirectorySizeLimit: 40
  }
}

resource appServicePlanName_scaleset 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${appServicePlanName_var}-scaleset'
  location: location
  tags: {
    'hidden-link:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}': 'Resource'
  }
  properties: {
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: '1'
          maximum: '2'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 80
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT1H'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 60
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1H'
            }
          }
        ]
      }
    ]
    enabled: false
    name: '${appServicePlanName_var}-scaleset'
    targetResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
  }
  dependsOn: [
    appServicePlanName
  ]
}

resource umbracoAdminWebAppName 'Microsoft.Web/sites@2022-03-01' = {
  name: umbracoAdminWebAppName_var
  location: location
  tags: {
    'hidden-related:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}': 'empty'
  }
  properties: {
    serverFarmId: appServicePlanName.id
  }
}

resource umbracoAdminWebAppName_MSDeploy 'Microsoft.Web/sites/extensions@2021-02-01' = {
  parent: umbracoAdminWebAppName
  name: 'MSDeploy'
  properties: {
    packageUri: packageUri
    dbType: 'SQL'
    connectionString: 'Data Source=tcp:${dbServerName_resource.properties.fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
    setParameters: {
      'Application Path': umbracoAdminWebAppName_var
      'Database Server': dbServerName_resource.properties.fullyQualifiedDomainName
      'Database Name': dbName
      'Database Username': '${nonAdminDatabaseUsername}admin'
      'Database Password': nonAdminDatabasePassword
      'Database Administrator': dbAdministratorLogin
      'Database Administrator Password': dbAdministratorLoginPassword
      azurestoragerootUrl: 'https://${storageAccountName_var}.blob.${environment().suffixes.storage}'
      azurestoragecontainerName: 'media'
      azurestorageconnectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName_var, '2021-04-01').keys[0].value}'
      rediscachehost: '${redisCacheName}.redis.cache.windows.net'
      rediscacheport: '6379'
      rediscacheaccessKey: listKeys(redisCacheName_resource.id, '2020-06-01').primaryKey
      azurestoragecacheControl: '*|public, max-age=31536000;js|no-cache'
    }
  }
  dependsOn: [

    umbracoAdminWebAppName_web
    dbServerName_dbName
    storageAccountName
  ]
}

resource umbracoAdminWebAppName_connectionstrings 'Microsoft.Web/Sites/config@2020-12-01' = {
  parent: umbracoAdminWebAppName
  name: 'connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Data Source=tcp:${dbServerName_resource.properties.fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
  dependsOn: [

    dbServerName_dbName
    umbracoAdminWebAppName_MSDeploy
  ]
}

resource umbracoAdminWebAppName_web 'Microsoft.Web/Sites/config@2020-12-01' = {
  parent: umbracoAdminWebAppName
  name: 'web'
  properties: {
    phpVersion: 'off'
    netFrameworkVersion: 'v4.5'
    use32BitWorkerProcess: true
    webSocketsEnabled: true
    alwaysOn: true
    httpLoggingEnabled: true
    logsDirectorySizeLimit: 40
  }
}
