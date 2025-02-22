resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stg${uniqueString(deployment().name, environment().name)}'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: {
    deployedBy: deployer().objectId
    deploymentName: deployment().name
    environmentName: environment().name
  }
}
