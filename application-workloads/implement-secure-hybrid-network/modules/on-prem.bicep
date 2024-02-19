param adminUserName string

@secure()
param adminPassword string
param mocOnpremNetwork object = {
  name: 'vnet-onprem'
  addressPrefix: '192.168.0.0/16'
  subnetName: 'mgmt'
  subnetPrefix: '192.168.1.128/25'
}
param mocOnpremGateway object = {
  name: 'vpn-mock-prem'
  subnetName: 'GatewaySubnet'
  subnetPrefix: '192.168.255.224/27'
  publicIPAddressName: 'pip-onprem-vpn-gateway'
}
param bastionHost object = {
  name: 'AzureBastionHost'
  subnetName: 'AzureBastionSubnet'
  subnetPrefix: '192.168.254.0/27'
  publicIPAddressName: 'pip-bastion'
  nsgName: 'nsg-hub-bastion'
}
param vmSize string = 'Standard_A1_v2'
param configureSitetosite bool = true
param location string

var nicNameWindows_var = 'nic-windows'
var vmNameWindows_var = 'vm-windows'
var windowsOSVersion = '2016-Datacenter'

resource mocOnpremNetwork_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: mocOnpremNetwork.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [mocOnpremNetwork.addressPrefix]
    }
    subnets: [
      {
        name: mocOnpremNetwork.subnetName
        properties: {
          addressPrefix: mocOnpremNetwork.subnetPrefix
        }
      }
      {
        name: mocOnpremGateway.subnetName
        properties: {
          addressPrefix: mocOnpremGateway.subnetPrefix
        }
      }
      {
        name: bastionHost.subnetName
        properties: {
          addressPrefix: bastionHost.subnetPrefix
        }
      }
    ]
  }
}

resource mocOnpremGateway_publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' =
  if (configureSitetosite) {
    name: mocOnpremGateway.publicIPAddressName
    location: location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
  }

resource mocOnpremGateway_name 'Microsoft.Network/virtualNetworkGateways@2019-11-01' =
  if (configureSitetosite) {
    name: mocOnpremGateway.name
    location: location
    properties: {
      ipConfigurations: [
        {
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: resourceId(
                'Microsoft.Network/virtualNetworks/subnets',
                mocOnpremNetwork.name,
                mocOnpremGateway.subnetName
              )
            }
            publicIPAddress: {
              id: mocOnpremGateway_publicIPAddress.id
            }
          }
          name: 'vnetGatewayConfig'
        }
      ]
      sku: {
        name: 'VpnGw2'
        tier: 'VpnGw2'
      }
      gatewayType: 'Vpn'
      vpnType: 'RouteBased'
      enableBgp: false
      bgpSettings: {
        asn: 60001
      }
    }
    dependsOn: [mocOnpremNetwork_name]
  }

resource bastionHost_publicIPAddress 'Microsoft.Network/publicIpAddresses@2020-05-01' = {
  name: bastionHost.publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost_nsg 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: bastionHost.nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'bastion-in-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-control-in-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-in-host'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: ['8080', '5701']
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-vnet-out-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: ['22', '3389']
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-azure-out-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-out-host'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: ['8080', '5701']
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-out-deny'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource bastionHost_name 'Microsoft.Network/bastionHosts@2020-06-01' = {
  name: bastionHost.name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId(
              'Microsoft.Network/virtualNetworks/subnets',
              mocOnpremNetwork.name,
              bastionHost.subnetName
            )
          }
          publicIPAddress: {
            id: bastionHost_publicIPAddress.id
          }
        }
      }
    ]
  }
  dependsOn: [mocOnpremNetwork_name]
}

resource nicNameWindows 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicNameWindows_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(
              'Microsoft.Network/virtualNetworks/subnets',
              mocOnpremNetwork.name,
              mocOnpremNetwork.subnetName
            )
          }
        }
      }
    ]
  }
  dependsOn: [mocOnpremNetwork_name]
}

resource vmNameWindows 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmNameWindows_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNameWindows_var
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicNameWindows.id
        }
      ]
    }
  }
}

output vpnIp string = mocOnpremGateway_name.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]
output mocOnpremNetworkPrefix string = mocOnpremNetwork.addressPrefix
output mocOnpremGatewayName string = mocOnpremGateway.name
