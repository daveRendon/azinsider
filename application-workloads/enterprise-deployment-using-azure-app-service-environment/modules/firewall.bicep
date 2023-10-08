@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location
param vnetName string

@description('The ip prefix the firewall will use.')
param firewallSubnetPrefix string

var firewallSubnetName = 'AzureFirewallSubnet'
var firewallPublicIpName = 'firewallIp-${uniqueString(resourceGroup().id)}'
var firewallName = 'firewall-${uniqueString(resourceGroup().id)}'

resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${vnetName}/${firewallSubnetName}'
  properties: {
    addressPrefix: firewallSubnetPrefix
    serviceEndpoints: [
      {
        service: 'Microsoft.AzureCosmosDB'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.KeyVault'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.ServiceBus'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.Sql'
        locations: [
          location
        ]
      }
    ]
  }
}

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  location: location
  name: firewallPublicIpName
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: firewallName
  location: location
  properties: {
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'clusterIpConfig'
        properties: {
          publicIPAddress: {
            id: firewallPublicIp.id
          }
          subnet: {
            id: firewallSubnet.id
          }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'Time'
        properties: {
          priority: 300
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'NTP'
              protocols: [
                'Any'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '123'
              ]
            }
            {
              name: 'Triage'
              protocols: [
                'Any'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '12000'
              ]
            }
          ]
        }
      }
      {
        name: 'AzureMonitor'
        properties: {
          priority: 500
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AzureMonitor'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                'AzureMonitor'
              ]
              destinationPorts: [
                '80'
                '443'
              ]
            }
          ]
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'AppServiceEnvironment'
        properties: {
          priority: 500
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AppServiceEnvironment'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: [
                'AppServiceEnvironment'
                'WindowsUpdate'
              ]
              sourceAddresses: [
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
}

output firewallSubnetName string = firewallSubnetName
