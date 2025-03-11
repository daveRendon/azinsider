param vnetManagerName string
param location string
param description string = ''
param tagsByResource object = {}
param networkManagerScopes object = {}
param networkManagerScopeAccesses array = []

resource vnetManager 'Microsoft.Network/networkmanagers@2022-01-01' = {
  name: vnetManagerName
  location: location
  tags: tagsByResource
  properties: {
    displayName: vnetManagerName
    description: description
    networkManagerScopes: networkManagerScopes
    networkManagerScopeAccesses: networkManagerScopeAccesses
  }
}
