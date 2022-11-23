@description('Name of the Event Hubs namespace')
param eventhubNamespaceName string

@description('Name of the Virtual Network')
param vnetName string

@description('Name of the Virtual Network Sub Net')
param subnetName string

@description('Location for Namespace')
param location string = resourceGroup().location

var namespaceVirtualNetworkRuleName = '${eventhubNamespaceName}/${vnetName}'
var subNetId = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName, subnetName)

resource eventhubNamespace 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: eventhubNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
  }
}

resource vnetRule 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/23'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/23'
          serviceEndpoints: [
            {
              service: 'Microsoft.EventHub'
            }
          ]
        }
      }
    ]
  }
}

resource eventhubNamespaceVnetRule 'Microsoft.EventHub/namespaces/VirtualNetworkRules@2018-01-01-preview' = {
  name: namespaceVirtualNetworkRuleName
  properties: {
    virtualNetworkSubnetId: subNetId
  }
  dependsOn: [
    eventhubNamespace
  ]
}
