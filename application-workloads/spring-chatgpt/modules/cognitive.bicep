param accountName string

param location string = resourceGroup().location
param deployments array = []

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: accountName
  location: location
  
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: accountName
  }
}

@batchSize(1)
resource embedding 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: account
  name: deployment.name
  properties: {
    model: deployment.model
  }
  sku: {
	name: 'Standard'
	capacity: deployment.capacity
  }
}]

output endpoint string = account.properties.endpoint
output key string = account.listKeys().key1
