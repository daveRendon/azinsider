@description('The location of this regional hub. All resources, including spoke resources, will be deployed to this region. This region must support availability zones.')
@minLength(6)
param location string = resourceGroup().location

@description('Set to true to include a basic VPN Gateway deployment into the hub. Set to false to leave network space for a VPN Gateway, but do not deploy one. Default is false. Note deploying VPN gateways can take significant time.')
param deployVpnGateway bool = false

@description('Set to true to include one Windows and one Linux virtual machine for you to experience peering, gateway transit, and bastion access. Default is false.')
param deployVirtualMachines bool = false

@minLength(4)
@maxLength(20)
@description('Username for both the Linux and Windows VM. Must only contain letters, numbers, hyphens, and underscores and may not start with a hyphen or number. Only needed when providing deployVirtualMachines=true.')
param adminUsername string = 'azureadmin'

@secure()
@maxLength(70)
@description('Password for both the Linux and Windows VM. ')
param adminPassword string

var suffix = uniqueString(subscription().subscriptionId, resourceGroup().id)
var numFirewallIpAddressesToAssign = 3

resource laHub 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'la-hub-${location}-${suffix}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      disableLocalAuth: false
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

resource laHub_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: laHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The NSG around the Azure Bastion subnet. Source: https://learn.microsoft.com/azure/bastion/bastion-nsg')
resource nsgBastionSubnet 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-${location}-bastion'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowWebExperienceInbound'
        properties: {
          description: 'Allow our users in.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowControlPlaneInbound'
        properties: {
          description: 'Allow control plane access.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHealthProbesInbound'
        properties: {
          description: ' Allow Health Probes.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostToHostInbound'
        properties: {
          description: 'Allow Required Host to Host Communication.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'No further inbound traffic allowed.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshToVnetOutbound'
        properties: {
          description: 'Allow SSH out to the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowRdpToVnetOutbound'
        properties: {
          description: 'Allow RDP out to the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowControlPlaneOutbound'
        properties: {
          description: 'Required for control plane outbound'
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
        name: 'AllowBastionHostToHostOutbound'
        properties: {
          description: 'Allow Required Host to Host Communication.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionCertificateValidationOutbound'
        properties: {
          description: 'Allow Required Session and Certificate Validation.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          description: 'No further outbound traffic allowed.'
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

resource nsgBastionSubnet_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsgBastionSubnet
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource vnetHub 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/26'
          networkSecurityGroup: {
            id: nsgBastionSubnet.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/27'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.3.0/26'
        }
      }
    ]
  }

  resource azureBastionSubnet 'subnets' existing = {
    name: 'AzureBastionSubnet'
  }

  resource gatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }

  resource azureFirewallSubnet 'subnets' existing = {
    name: 'AzureFirewallSubnet'
  }

  resource peerToSpokeOne 'virtualNetworkPeerings@2022-01-01' = {
    name: 'to_${vnetSpokeOne.name}'
    dependsOn: [
      vnetSpokeOne::peerToHub 
    ]
    properties: {
      allowForwardedTraffic: false
      allowGatewayTransit: false
      allowVirtualNetworkAccess: true
      useRemoteGateways: false
      remoteVirtualNetwork: {
        id: vnetSpokeOne.id
      }
    }
  }

  resource peerToSpokeTwo 'virtualNetworkPeerings@2022-01-01' = {
    name: 'to_${vnetSpokeTwo.name}'
    dependsOn: [
      vnetSpokeTwo::peerToHub 
    ]
    properties: {
      allowForwardedTraffic: false
      allowGatewayTransit: false
      allowVirtualNetworkAccess: true
      useRemoteGateways: false
      remoteVirtualNetwork: {
        id: vnetSpokeTwo.id
      }
    }
  }
}

resource vnetHub_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: vnetHub
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}


resource pipsAzureFirewall 'Microsoft.Network/publicIPAddresses@2022-01-01' = [for i in range(0, numFirewallIpAddressesToAssign): {
  name: 'pip-fw-${location}-${padLeft(i, 2, '0')}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}]

resource pipsAzureFirewall_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for i in range(0, numFirewallIpAddressesToAssign): {
  name: 'to-hub-la'
  scope: pipsAzureFirewall[i]
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}]

@description('Azure Firewall Policy')
resource fwPolicy 'Microsoft.Network/firewallPolicies@2022-01-01' = {
  name: 'fw-policies-${location}'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
    insights: {
      isEnabled: true
      retentionDays: 30
      logAnalyticsResources: {
        defaultWorkspaceId: {
          id: laHub.id
        }
      }
    }
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
    intrusionDetection: null 
    dnsSettings: {
      servers: []
      enableProxy: true
    }
  }


  resource defaultNetworkRuleCollectionGroup 'ruleCollectionGroups@2022-01-01' = {
    name: 'DefaultNetworkRuleCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          name: 'org-wide-allowed'
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              ruleType: 'NetworkRule'
              name: 'DNS'
              description: 'Allow DNS outbound (for simplicity, adjust as needed)'
              ipProtocols: [
                'UDP'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
              destinationAddresses: [
                '*'
              ]
              destinationIpGroups: []
              destinationFqdns: []
              destinationPorts: [
                '53'
              ]
            }
          ]
        }
      ]
    }
  }

  resource defaultApplicationRuleCollectionGroup 'ruleCollectionGroups@2022-01-01' = {
    name: 'DefaultApplicationRuleCollectionGroup'
    dependsOn: [
      defaultNetworkRuleCollectionGroup
    ]
    properties: {
      priority: 300
      ruleCollections: [ 
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          name: 'org-wide-allowed'
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: deployVirtualMachines ? [
            {
              ruleType: 'ApplicationRule'
              name: 'WindowsVirtualMachineHealth'
              description: 'Supports Windows Updates and Windows Diagnostics'
              fqdnTags: [
                'WindowsDiagnostics'
                'WindowsUpdate'
              ]
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              sourceAddresses: [
                '10.200.0.0/24' 
              ]
            }
          ] : []
        }
      ]
    }
  }
}

resource fwHub 'Microsoft.Network/azureFirewalls@2022-01-01' = {
  name: 'fw-${location}'
  location: location
  zones: [
    '1'
    '2'
    '3'
  ]
  dependsOn: [
    fwPolicy::defaultApplicationRuleCollectionGroup
    fwPolicy::defaultNetworkRuleCollectionGroup
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: fwPolicy.id
    }
    ipConfigurations: [for i in range(0, numFirewallIpAddressesToAssign): {
      name: pipsAzureFirewall[i].name
      properties: {
        subnet: (0 == i) ? {
          id: vnetHub::azureFirewallSubnet.id
        } : null
        publicIPAddress: {
          id: pipsAzureFirewall[i].id
        }
      }
    }]
  }
}

resource fwHub_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: fwHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The public IP for the regional hub\'s Azure Bastion service.')
resource pipAzureBastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'pip-ab-${location}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource pipAzureBastion_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: pipAzureBastion
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource azureBastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'ab-${location}-${suffix}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'hub-subnet'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnetHub::azureBastionSubnet.id
          }
          publicIPAddress: {
            id: pipAzureBastion.id
          }
        }
      }
    ]
  }
}

resource azureBastion_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: azureBastion
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource pipVpnGateway 'Microsoft.Network/publicIPAddresses@2022-01-01' = if (deployVpnGateway) {
  name: 'pip-vgw-${location}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource pipVpnGateway_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVpnGateway) {
  name: 'to-hub-la'
  scope: pipVpnGateway
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource vgwHub 'Microsoft.Network/virtualNetworkGateways@2022-01-01' = if (deployVpnGateway) {
  name: 'vgw-${location}-hub'
  location: location
  properties: {
    sku: {
      name: 'VpnGw2AZ'
      tier: 'VpnGw2AZ'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipVpnGateway.id
          }
          subnet: {
            id: vnetHub::gatewaySubnet.id
          }
        }
      }
    ]
  }
}

resource vgwHub_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVpnGateway) {
  name: 'to-hub-la'
  scope: vgwHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource routeNextHopToFirewall 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'route-to-${location}-hub-fw'
  location: location
  properties: {
    routes: [
      {
        name: 'r-nexthop-to-fw'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwHub.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

resource nsgResourcesSubnet 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-spoke-resources'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowBastionRdpFromHub'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: vnetHub::azureBastionSubnet.properties.addressPrefix
          destinationPortRanges: [
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionSshFromHub'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: vnetHub::azureBastionSubnet.properties.addressPrefix
          destinationPortRanges: [
            '22'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgResourcesSubnet_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsgResourcesSubnet
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource nsgPrivateLinkEndpointsSubnet 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-spoke-privatelinkendpoints'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAll443InFromVnet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource nsgPrivateLinkEndpointsSubnet_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsgPrivateLinkEndpointsSubnet
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource vnetSpokeOne 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-spoke-one'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'snet-resources'
        properties: {
          addressPrefix: '10.100.0.0/24'
          networkSecurityGroup: {
            id: nsgResourcesSubnet.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: routeNextHopToFirewall.id
          }
        }
      }
      {
        name: 'snet-privatelinkendpoints'
        properties: {
          addressPrefix: '10.100.1.0/26'
          networkSecurityGroup: {
            id: nsgPrivateLinkEndpointsSubnet.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: routeNextHopToFirewall.id
          }
        }
      }
    ]
  }

  resource snetResources 'subnets' existing = {
    name: 'snet-resources'
  }

  resource peerToHub 'virtualNetworkPeerings@2022-01-01' = {
    name: 'to_${vnetHub.name}'
    properties: {
      allowForwardedTraffic: false
      allowGatewayTransit: false
      allowVirtualNetworkAccess: true
      useRemoteGateways: false
      remoteVirtualNetwork: {
        id: vnetHub.id
      }
    }
  }
}

resource vnetSpokeOne_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vnetSpokeOne
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource nicVmSpokeOneLinux 'Microsoft.Network/networkInterfaces@2022-01-01' = if (deployVirtualMachines) {
  name: 'nic-vm-${location}-spoke-one-linux'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: vnetSpokeOne::snetResources.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

resource nicVmSpokeOneLinux_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVirtualMachines) {
  scope: nicVmSpokeOneLinux
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource vmSpokeOneLinux 'Microsoft.Compute/virtualMachines@2022-03-01' = if (deployVirtualMachines) {
  name: 'vm-${location}-spoke-one-linux'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ds_v4'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        caching: 'ReadOnly'
        diffDiskSettings: {
          option: 'Local'
          placement: 'CacheDisk'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      dataDisks: []
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: null
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicVmSpokeOneLinux.id
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'examplevm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    priority: 'Regular'
  }
}


resource vnetSpokeTwo 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-spoke-two'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'snet-resources'
        properties: {
          addressPrefix: '10.200.0.0/24'
          networkSecurityGroup: {
            id: nsgResourcesSubnet.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: routeNextHopToFirewall.id
          }
        }
      }
      {
        name: 'snet-privatelinkendpoints'
        properties: {
          addressPrefix: '10.200.1.0/26'
          networkSecurityGroup: {
            id: nsgPrivateLinkEndpointsSubnet.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: routeNextHopToFirewall.id
          }
        }
      }
    ]
  }

  resource snetResources 'subnets' existing = {
    name: 'snet-resources'
  }

  resource peerToHub 'virtualNetworkPeerings@2022-01-01' = {
    name: 'to_${vnetHub.name}'
    properties: {
      allowForwardedTraffic: false
      allowGatewayTransit: false
      allowVirtualNetworkAccess: true
      useRemoteGateways: false
      remoteVirtualNetwork: {
        id: vnetHub.id
      }
    }
  }
}

resource vnetSpokeTwo_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vnetSpokeTwo
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource nicVmSpokeTwoLinux 'Microsoft.Network/networkInterfaces@2022-01-01' = if (deployVirtualMachines) {
  name: 'nic-vm-${location}-spoke-two-windows'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: vnetSpokeTwo::snetResources.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

resource nicVmSpokeTwoLinux_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVirtualMachines) {
  scope: nicVmSpokeTwoLinux
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource vmSpokeTwoWindows 'Microsoft.Compute/virtualMachines@2022-03-01' = if (deployVirtualMachines) {
  name: 'vm-${location}-spoke-two-windows'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      dataDisks: []
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: null
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicVmSpokeTwoLinux.id
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'examplevm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    priority: 'Regular'
  }
}
