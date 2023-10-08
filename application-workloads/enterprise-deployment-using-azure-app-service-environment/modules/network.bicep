@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The IP address prefix the network will use.')
param vnetAddressPrefix string

@description('The name of the vnet to use. Leave empty to create a new vnet.')
param existentVnetName string = ''

var mustCreateVNet = empty(existentVnetName)
var vnetName = (empty(existentVnetName) ? 'ASE-VNET${uniqueString(resourceGroup().id)}' : existentVnetName)
var vnetRouteName = 'ASE-VNETRT${uniqueString(resourceGroup().id)}'

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = if (mustCreateVNet) {
  name: vnetName
  location: location
  tags: {
    displayName: 'ASE-VNET'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource vnetRoute 'Microsoft.Network/routeTables@2022-01-01' = {
  name: vnetRouteName
  location: location
  tags: {
    displayName: 'UDR - Subnet'
  }
  properties: {
    routes: [
      {
        name: '${vnetRouteName}-route'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output vnetRouteName string = vnetRoute.name
