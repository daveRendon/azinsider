param location string = resourceGroup().location

// Azure Firewall 
param firewallIpName string
param firewallName string
param privateendpointnicname string

// Virtual Network 
param virtualNetworkName string

// Web App 
param webAppName string

resource firewallip 'Microsoft.Network/publicIPAddresses@2021-02-01' existing = {
  name: firewallIpName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
}

resource privateendpointnic 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
  name: privateendpointnicname
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'AzureFirewallIpConfiguration0'
        properties: {
          publicIPAddress: {
            id: firewallip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, virtualNetwork.properties.subnets[0].name)
          }
        }
      }
    ]
    natRuleCollections: [
      {
        name: 'WebAppDNAT'
        properties: {
          priority: 100
          action: {
            type: 'Dnat'
          }
          rules: [
            {
              name: webAppName
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                firewallip.properties.ipAddress
              ]
              destinationPorts: [
                '443'
              ]
              translatedAddress: privateendpointnic.properties.ipConfigurations[0].properties.privateIPAddress
              translatedPort: '443'
              description: 'DNAT to WebApp private endpoint'
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'WebAppToInternet'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'subnet-webapp'
              protocols: [
                'Any'
              ]
              sourceAddresses: [
                virtualNetwork.properties.subnets[2].properties.addressPrefix
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '*'
              ]
            }
          ]

        }
      }
    ]
  }
}

output firewallPublicIp string = firewallip.properties.ipAddress
