@description('Prefix for resource names.')
param resourceNamePrefix string 

@description('SQL administrator login')
param sqlAdminLogin string = 'sqlAdmin'

param location string = resourceGroup().location

resource resourceNamePrefix_sql 'Microsoft.Sql/servers@2023-08-01' = {
  name: '${resourceNamePrefix}-sql'
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: 'Simple123'
    version: '12.0'
  }
}

resource resourceNamePrefix_sql_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2023-08-01' = {
  parent: resourceNamePrefix_sql
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource resourceNamePrefix_sql2 'Microsoft.Sql/servers@2023-08-01' = {
  name: '${resourceNamePrefix}-sql2'
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: 'Simple123'
    version: '12.0'
  }
}

resource resourceNamePrefix_sql2_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2023-08-01' = {
  parent: resourceNamePrefix_sql2
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource resourceNamePrefix_kv 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: '${resourceNamePrefix}-kv'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
  }
  dependsOn: []
}
