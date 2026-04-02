param keyVaultName string
param functionAppName string
param cosmosAccountName string
param deploymentScriptServicePrincipalId string
param resourceTags object

var keyVaultSecretName = '${cosmosAccountName}-key'

resource functionApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: functionAppName
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: functionApp.identity.tenantId
        objectId: functionApp.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
  tags: resourceTags
}

resource deploymentScripts 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'getConnectionString'
  kind: 'AzurePowerShell'
  location: resourceGroup().location
  identity:{
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${deploymentScriptServicePrincipalId}': {}
    }
  }
  properties: {
    azPowerShellVersion: '6.1'
    timeout: 'PT30M'
    arguments: '-accountName ${cosmosAccountName} -resourceGroup ${resourceGroup().name}'
    scriptContent: '''
      param([string] $accountName, [string] $resourceGroup)
      $connectionStrings = Get-AzCosmosDBAccountKey `
      -ResourceGroupName $resourceGroup `
      -Name $accountName `
      -Type "ConnectionStrings"
      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['connectionString'] = $connectionStrings["Primary MongoDB Connection String"]
    '''
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
  }
}

resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name : keyVaultSecretName
  properties: {
    value: deploymentScripts.properties.outputs.connectionString
  }
}
