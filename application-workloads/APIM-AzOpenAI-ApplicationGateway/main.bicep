@description('Resource prefix for naming resources')
param resourcePrefix string 

@description('Azure region for deployment')
param location string 

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${resourcePrefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'apimSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'appGwSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'privateEndpointSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Network Security Group for APIM Subnet
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${resourcePrefix}-apim-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowMgmtInbound'
        properties: {
          priority: 100
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'ApiManagement'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3443'
        }
      }
    ]
  }
}

// Azure OpenAI instance
resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: '${resourcePrefix}-openai'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: '${resourcePrefix}-openai'
  }
}

// Private Endpoint for Azure OpenAI
resource openAiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${resourcePrefix}-openai-pe'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/privateEndpointSubnet'
    }
    privateLinkServiceConnections: [
      {
        name: 'openaiPrivateLink'
        properties: {
          privateLinkServiceId: openAi.id
          groupIds: ['account']
        }
      }
    ]
  }
}

// API Management (Internal VNet)
resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: '${resourcePrefix}-apim'
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@contoso.com'
    publisherName: 'Contoso Admin'
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: '${vnet.id}/subnets/apimSubnet'
    }
  }
  dependsOn: [
    vnet
    nsg
  ]
}

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${resourcePrefix}-appgw-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Application Gateway (HTTP listener)
resource appGw 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: '${resourcePrefix}-appGw'
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/appGwSubnet'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIpConfig'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'httpPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apimBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: replace(apim.properties.gatewayUrl, 'https://', '')
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apimBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          hostName: replace(apim.properties.gatewayUrl, 'https://', '')
          probeEnabled: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', '${resourcePrefix}-appGw', 'apimProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'apimProbe'
        properties: {
          protocol: 'Https'
          host: replace(apim.properties.gatewayUrl, 'https://', '')
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          match: {
            statusCodes: ['200-399']
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', '${resourcePrefix}-appGw', 'frontendIpConfig')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', '${resourcePrefix}-appGw', 'httpPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'httpRoutingRule'
        properties: {
          priority: 100  // Priority added (value must be unique per rule)
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', '${resourcePrefix}-appGw', 'httpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', '${resourcePrefix}-appGw', 'apimBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', '${resourcePrefix}-appGw', 'apimBackendHttpSettings')
          }
        }
      }
    ]
    
  }
  dependsOn: [
    apim
    publicIp
  ]
}
