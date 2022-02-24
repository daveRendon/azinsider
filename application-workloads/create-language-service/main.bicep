@description('Location for all resources.')
param location string = resourceGroup().location
param name string
param sku string = 'F0'
param identity object
param virtualNetworkType string
param ipRules array
param subnet1Name string = 'subnet-1'
param vnetName string = 'virtualNetwork'


// This will build a Virtual Network.
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

// This will build a Face service.
resource name_resource 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: name
  location: location
  kind: 'TextAnalytics'
  sku: {
    name: sku
  }
  identity: identity
  properties: {
    customSubDomainName: toLower(name)
    publicNetworkAccess: ((virtualNetworkType == 'Internal') ? 'Disabled' : 'Enabled')
    networkAcls: {
      defaultAction: ((virtualNetworkType == 'External') ? 'Deny' : 'Allow')
      virtualNetworkRules: ((virtualNetworkType == 'External') ? json('[{"id": "${subscription().id}/resourceGroups/${vnet}/providers/Microsoft.Network/virtualNetworks/${vnet.name}/subnets/${subnet1Name}"}]') : json('[]'))
      ipRules: ((empty(ipRules) || empty(ipRules[0].value)) ? json('[]') : ipRules)
    }
  }
  dependsOn: [
    vnet
  ]
}
