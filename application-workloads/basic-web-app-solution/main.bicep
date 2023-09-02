@description('The admin user name for the Azure SQL instance.')
param adminUserName string

@description('The admin password for the Azure SQL instance.')
@secure()
param adminPassword string
param emailAddress string

@description('Deployment settings for the Log Analytics workspace.')
param logAnalytics object = {
  name: 'la-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
  skuName: 'PerGB2018'
}

@description('Deployment settings for Azure SQL and Azure SQL database instances.')
param azureSqlDatabase object = {
  serverName: 'sql-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
  databaseName: 'appdb'
  collation: 'SQL_Latin1_General_CP1_CI_AS'
  edition: 'Standard'
  maxSizeBytes: '1073741824'
  requestedServiceObjectiveName: 'S0'
}

@description('Deployment settings for Azure Key Vault instances.')
param keyVault object = {
  name: 'kv-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
  skuName: 'standard'
  skuFamily: 'A'
}

@description('Deployment settings for Azure App Service instance.')
param azureAppService object = {
  name: 'app-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
  webSiteName: 'app-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
  skuName: 'S1'
  skuCapacity: 1
  autoScaleCpuMax: '80'
  autoScaleCpuMin: '60'
  autoScaleMin: 1
  autoscaleMax: 2
  autoscaleDefault: 1
}
param deploySlots bool = true
param location string = resourceGroup().location

resource logAnalytics_name 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalytics.name
  location: location
  properties: {
    sku: {
      name: logAnalytics.skuName
    }
    features: {
      searchVersion: 1
    }
  }
}

resource azureSqlDatabase_server 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: azureSqlDatabase.serverName
  location: location
  properties: {
    administratorLogin: adminUserName
    administratorLoginPassword: adminPassword
    version: '12.0'
  }
}

resource azureSqlDatabase_serverName_master 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${azureSqlDatabase.serverName}/master'
  location: location
  dependsOn: [
    azureSqlDatabase_server
  ]
}

resource azureSqlDatabase_serverName_master_Microsoft_Insights_default_logAnalytics_name 'Microsoft.Sql/servers/databases/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${azureSqlDatabase.serverName}/master/Microsoft.Insights/default${logAnalytics.name}'
  properties: {
    workspaceId: logAnalytics_name.id
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
      }
    ]
  }
  dependsOn: [

    azureSqlDatabase_serverName_master
  ]
}

resource azureSqlDatabase_serverName_DefaultAuditingSettings 'Microsoft.Sql/servers/auditingSettings@2020-02-02-preview' = {
  name: '${azureSqlDatabase.serverName}/DefaultAuditingSettings'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
  }
  dependsOn: [
    azureSqlDatabase_server
  ]
}

resource azureSqlDatabase_serverName_azureSqlDatabase_database 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${azureSqlDatabase.serverName}/${azureSqlDatabase.databaseName}'
  location: location
  dependsOn: [
    azureSqlDatabase_server
  ]
}

resource azureSqlDatabase_serverName_azureSqlDatabase_databaseName_Microsoft_Insights_default_logAnalytics_name 'Microsoft.Sql/servers/databases/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${azureSqlDatabase.serverName}/${azureSqlDatabase.databaseName}/Microsoft.Insights/default${logAnalytics.name}'
  properties: {
    workspaceId: logAnalytics_name.id
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
      }
      {
        category: 'Timeouts'
        enabled: true
      }
      {
        category: 'Blocks'
        enabled: true
      }
      {
        category: 'Deadlocks'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
      {
        category: 'InstanceAndAppAdvanced'
        enabled: true
      }
      {
        category: 'WorkloadManagement'
        enabled: true
      }
    ]
  }
  dependsOn: [

    azureSqlDatabase_serverName_azureSqlDatabase_database
    azureSqlDatabase_serverName_master
  ]
}

resource azureSqlDatabase_serverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  name: '${azureSqlDatabase.serverName}/AllowAllWindowsAzureIps'
  location: location
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    azureSqlDatabase_server
  ]
}

resource keyVault_name 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVault.name
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: subscription().tenantId
    sku: {
      name: keyVault.skuName
      family: keyVault.skuFamily
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(azureAppService_webSite.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          secrets: [
            'Get'
          ]
        }
      }
    ]
  }
}

resource keyVault_name_Microsoft_Insights_default_azureAppService_name 'Microsoft.KeyVault/vaults/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${keyVault.name}/Microsoft.Insights/default${azureAppService.name}'
  properties: {
    workspaceId: logAnalytics_name.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    keyVault_name
  ]
}

resource keyVault_name_sqlServer 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVault.name}/sqlServer'
  properties: {
    value: 'Data Source=tcp:${azureSqlDatabase_server.properties.fullyQualifiedDomainName},1433;Initial Catalog=${azureSqlDatabase.databaseName};User Id=${adminUserName}@${azureSqlDatabase.serverName};Password=${adminPassword};'
  }
  dependsOn: [
    keyVault_name

  ]
}

resource azureAppService_name 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: azureAppService.name
  location: location
  sku: {
    name: azureAppService.skuName
    capacity: azureAppService.skuCapacity
  }
  kind: 'linux'
  properties: {
    name: azureAppService.name
    reserved: true
  }
}

resource azureAppService_name_Microsoft_Insights_default_azureAppService_name 'Microsoft.Web/serverfarms/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${azureAppService.name}/Microsoft.Insights/default${azureAppService.name}'
  properties: {
    workspaceId: logAnalytics_name.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    azureAppService_name
  ]
}

resource azureAppService_webSite 'Microsoft.Web/sites@2020-06-01' = {
  name: azureAppService.webSiteName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    name: azureAppService.webSiteName
    serverFarmId: azureAppService_name.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.7'
    }
  }
}

resource azureAppService_webSiteName_connectionstrings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${azureAppService.webSiteName}/connectionstrings'
  properties: {
    DefaultConnection: {
      value: '@Microsoft.KeyVault(SecretUri=${keyVault_name_sqlServer.properties.secretUriWithVersion})'
      type: 'SQLServer'
    }
  }
  dependsOn: [
    azureAppService_webSite
  ]
}

resource azureAppService_webSiteName_Microsoft_Insights_default_azureAppService_name 'Microsoft.Web/sites/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${azureAppService.webSiteName}/Microsoft.Insights/default${azureAppService.name}'
  properties: {
    workspaceId: logAnalytics_name.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    azureAppService_webSite
  ]
}

resource azureAppService_webSiteName_Staging 'Microsoft.Web/sites/slots@2020-06-01' = if (deploySlots) {
  name: '${azureAppService.webSiteName}/Staging'
  location: location
  properties: {}
  dependsOn: [
    azureAppService_webSite
  ]
}

resource azureAppService_webSiteName_Staging_connectionstrings 'Microsoft.Web/sites/slots/config@2020-06-01' = if (deploySlots) {
  name: '${azureAppService.webSiteName}/Staging/connectionstrings'
  properties: {
    DefaultConnection: {
      value: '@Microsoft.KeyVault(SecretUri=${keyVault_name_sqlServer.properties.secretUriWithVersion})'
      type: 'SQLServer'
    }
  }
  dependsOn: [
    azureAppService_webSiteName_Staging
  ]
}

resource azureAppService_webSiteName_Staging_Microsoft_Insights_default_azureAppService_name 'Microsoft.Web/sites/slots/providers/diagnosticSettings@2017-05-01-preview' = if (deploySlots) {
  name: '${azureAppService.webSiteName}/Staging/Microsoft.Insights/default${azureAppService.name}'
  properties: {
    workspaceId: logAnalytics_name.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    azureAppService_webSiteName_Staging
  ]
}

resource azureAppService_webSiteName_LastKnownGood 'Microsoft.Web/sites/slots@2020-06-01' = if (deploySlots) {
  name: '${azureAppService.webSiteName}/LastKnownGood'
  location: location
  properties: {}
  dependsOn: [
    azureAppService_webSite
  ]
}

resource azureAppService_webSiteName_LastKnownGood_connectionstrings 'Microsoft.Web/sites/slots/config@2020-06-01' = if (deploySlots) {
  name: '${azureAppService.webSiteName}/LastKnownGood/connectionstrings'
  properties: {
    DefaultConnection: {
      value: '@Microsoft.KeyVault(SecretUri=${keyVault_name_sqlServer.properties.secretUriWithVersion})'
      type: 'SQLServer'
    }
  }
  dependsOn: [
    azureAppService_webSiteName_LastKnownGood
  ]
}

resource azureAppService_webSiteName_LastKnownGood_Microsoft_Insights_default_azureAppService_name 'Microsoft.Web/sites/slots/providers/diagnosticSettings@2017-05-01-preview' = if (deploySlots) {
  name: '${azureAppService.webSiteName}/LastKnownGood/Microsoft.Insights/default${azureAppService.name}'
  properties: {
    workspaceId: logAnalytics_name.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    azureAppService_webSiteName_LastKnownGood
  ]
}

resource azureAppService_name_name 'Microsoft.Insights/autoscalesettings@2015-04-01' = {
  name: '${azureAppService.name}-${resourceGroup().name}'
  location: location
  properties: {
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: azureAppService.autoScaleMin
          maximum: azureAppService.autoscaleMax
          default: azureAppService.autoscaleDefault
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${azureAppService.name}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: azureAppService.autoScaleCpuMax
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: 1
              cooldown: 'PT10M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${azureAppService.name}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT1H'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: azureAppService.autoScaleCpuMin
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: 1
              cooldown: 'PT1H'
            }
          }
        ]
      }
    ]
    enabled: true
    name: '${azureAppService.name}-${resourceGroup().name}'
    targetResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${azureAppService.name}'
  }
  dependsOn: [
    azureAppService_name
  ]
}

resource email_alert 'microsoft.insights/actionGroups@2019-06-01' = {
  name: 'email-alert'
  location: 'global'
  properties: {
    groupShortName: 'email-alert'
    enabled: true
    emailReceivers: [
      {
        name: 'emailAction'
        emailAddress: emailAddress
        useCommonAlertSchema: false
      }
    ]
  }
}

resource ServerErrors_azureAppService_webSite 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'ServerErrors ${azureAppService.webSiteName}'
  location: 'global'
  properties: {
    description: '${azureAppService.webSiteName} has some server errors, status code 5xx.'
    severity: 3
    enabled: true
    scopes: [
      azureAppService_webSite.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria: {
      allOf: [
        {
          threshold: 0
          name: 'ServerErrors ${azureAppService.webSiteName}'
          metricNamespace: 'Microsoft.Web/sites'
          metricName: 'Http5xx'
          operator: 'GreaterThan'
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Web/sites'
    actions: [
      {
        actionGroupId: email_alert.id
      }
    ]
  }
}

resource ForbiddenRequests_azureAppService_webSite 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'ForbiddenRequests ${azureAppService.webSiteName}'
  location: 'global'
  properties: {
    description: '${azureAppService.webSiteName} has some requests that are forbidden, status code 403.'
    severity: 3
    enabled: true
    scopes: [
      azureAppService_webSite.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria: {
      allOf: [
        {
          threshold: 0
          name: 'ForbiddenRequests ${azureAppService.webSiteName}'
          metricNamespace: 'Microsoft.Web/sites'
          metricName: 'Http403'
          operator: 'GreaterThan'
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Web/sites'
    actions: [
      {
        actionGroupId: email_alert.id
      }
    ]
  }
}

resource CPUHigh_azureAppService_name 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'CPUHigh ${azureAppService.name}'
  location: 'global'
  properties: {
    description: 'The average CPU is high across all the instances of ${azureAppService.name}'
    severity: 3
    enabled: true
    scopes: [
      azureAppService_name.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria: {
      allOf: [
        {
          threshold: 90
          name: 'CPUHigh ${azureAppService.name}'
          metricNamespace: 'Microsoft.Web/serverfarms'
          metricName: 'CpuPercentage'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Web/serverfarms'
    actions: [
      {
        actionGroupId: email_alert.id
      }
    ]
  }
}

resource LongHttpQueue_azureAppService_name 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'LongHttpQueue ${azureAppService.name}'
  location: 'global'
  properties: {
    description: 'The HTTP queue for the instances of ${azureAppService.name} has a large number of pending requests.'
    severity: 3
    enabled: true
    scopes: [
      azureAppService_name.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria: {
      allOf: [
        {
          threshold: '100'
          name: 'CPUHigh ${azureAppService.name}'
          metricNamespace: 'Microsoft.Web/serverfarms'
          metricName: 'HttpQueueLength'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Web/serverfarms'
    actions: [
      {
        actionGroupId: email_alert.id
      }
    ]
  }
}