param routetablename string
param location string = resourceGroup().location


// Virtual Network Parameters
param virtualNetworkName string
param webAppSubnet string

// Azure Firewall Parameters
param firewallName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' existing = {
  name: firewallName
}

resource routetable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: routetablename
  location: location
  properties: {
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
          hasBgpOverride: false
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualnetworks/subnets@2021-02-01' = {
  parent: virtualNetwork
  name: 'subnet-webapp'
  properties: {
      addressPrefix: webAppSubnet
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      delegations: [
        {
          name: 'delegation'
          properties: {
            serviceName: 'Microsoft.Web/serverFarms'
          }
        }
      ]
      routeTable: {
        id: routetable.id
      }
  }
}
