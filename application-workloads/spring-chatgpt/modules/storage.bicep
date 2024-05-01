param storageAccountName string
param fileShareName string
param location string = resourceGroup().location
param utcValue string = utcNow()
param filename string = '../../../doc_store.json'

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    largeFileSharesState: 'Enabled'
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${storage.name}/default/${fileShareName}'
  properties: {
    shareQuota: 1024
    enabledProtocols: 'SMB'
  }
}

output storageAccountKey string = storage.listKeys().keys[0].value
