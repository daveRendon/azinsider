param location string = 'eastus'
param vnet1Name string = 'vnet1'
param vnet2Name string = 'vnet2'
param vnet1AddressPrefix string = '10.0.0.0/16'
param vnet2AddressPrefix string = '10.1.0.0/16'
param subnet1Name string = 'subnet1'
param subnet2Name string = 'subnet2'
param subnet1Prefix string = '10.0.1.0/24'
param subnet2Prefix string = '10.1.1.0/24'

resource vnet1 'Microsoft.Network/virtualNetworks@2025-05-01' = {
  name: vnet1Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnet1AddressPrefix]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2025-05-01' = {
  name: vnet2Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnet2AddressPrefix]
    }
    subnets: [
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
    ]
  }
}

resource vnet1ToVnet2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-05-01' = {
  name: '${vnet1Name}-to-${vnet2Name}'
  parent: vnet1
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet2.id
    }
    localSubnetNames: [subnet1Name]
    remoteSubnetNames: [subnet2Name]
  }
}

resource vnet2ToVnet1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-05-01' = {
  name: '${vnet2Name}-to-${vnet1Name}'
  parent: vnet2
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet1.id
    }
    localSubnetNames: [subnet2Name]
    remoteSubnetNames: [subnet1Name]
  }
}
