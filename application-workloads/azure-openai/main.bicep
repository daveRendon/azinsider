param name string
param location string
param sku string

resource open_ai 'Microsoft.CognitiveServices/accounts@2022-03-01' = {
  name: name
  location: location
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: toLower(name)
  }
}
