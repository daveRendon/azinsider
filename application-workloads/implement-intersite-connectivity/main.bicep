@description('Virtual machine size')
param vmSize string = 'Standard_D2s_v3'

@description('First Azure Region')
param location1 string = 'eastus'

@description('Second Azure Region')
param location2 string = 'westus'

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

var locationNames = [
  location1
  location1
  location2
]

var vmName = 'az104-05-vm'
var nicName = 'az104-05-nic'
var subnetName = 'subnet0'
var vnetName = 'az104-05-vnet'
var pipName = 'az104-05-pip'
var nsgName = 'az104-05-nsg'
var vnet0 = 'az104-05-vnet0'
var vnet1 = 'az104-05-vnet1'
var vnet2 = 'az104-05-vnet2'
var remoteVnetRg = 'azinsider_demo'

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = [for (item, i) in locationNames: {
  name: '${vmName}${i}'
  location: item
  properties: {
    osProfile: {
      computerName: '${vmName}${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicName}${i}')
        }
      ]
    }
  }
  dependsOn: [
    nic
  ]
}]

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = [for (item, i) in locationNames: {
  name: '${vnetName}${i}'
  location: item
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.5${i}.0.0/22'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.5${i}.0.0/24'
        }
      }
    ]
  }
}]

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = [for (item, i) in locationNames: {
  name: '${nicName}${i}'
  location: item
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', '${vnetName}${i}', subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIpAddresses', '${pipName}${i}')
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', '${nsgName}${i}')
    }
  }
  dependsOn: [
    pip
    nsg
    vnet
  ]
}]

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = [for (item, i) in locationNames: {
  name: '${pipName}${i}'
  location: item
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = [for (item, i) in locationNames: {
  name: '${nsgName}${i}'
  location: item
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}]

//This creates a peering from vnet0 to vnet1
resource peer1 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vnet0}/peering-to-vnet1'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', vnet1)
    }
  }
  dependsOn:[
    vnet
  ]
}

//This creates a peering from vnet1 to vnet0
resource peer2 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vnet1}/peering-to-vnet0'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', vnet0)
    }
  }
  dependsOn:[
    vnet
  ]
}

//This creates a peering from vnet2 to vnet0
resource peer3 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vnet2}/peering-to-vnet0'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', vnet0)
    }
  }
  dependsOn:[
    vnet
  ]
}

//This creates a peering from vnet0 to vnet2
resource peer4 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vnet0}/peering-to-vnet2'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', vnet2)
    }
  }
  dependsOn:[
    vnet
  ]
}

//This creates a peering from vnet2 to vnet1
resource peer5 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vnet2}/peering-to-vnet1'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', vnet1)
    }
  }
  dependsOn:[
    vnet
  ]
}

//This creates a peering from vnet1 to vnet2
resource peer6 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${vnet1}/peering-to-vnet2'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', vnet2)
    }
  }
  dependsOn:[
    vnet
  ]
}
