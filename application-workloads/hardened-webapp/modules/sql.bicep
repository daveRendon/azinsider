param sqlName string
param sqlAdministratorLogin string
@secure()
param sqladministratorLoginPassword string

param location string = resourceGroup().location


// Virtual Network Parameters
param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
}

resource privatednszone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.database.windows.net'
}

resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqladministratorLoginPassword
    publicNetworkAccess: 'Disabled'
  }
}

resource privateendpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  dependsOn: [
    sqlServer
    privatednszone
  ]
  name: '${sqlName}-privateendpoint'
  location: resourceGroup().location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${sqlName}-peconnection'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
        }
      }
    ]
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, virtualNetwork.properties.subnets[1].name)
    }
  }
}

resource privatednszonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: privateendpoint
  dependsOn: [
    sqlServer
    privatednszone
  ]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-database-windows-net'
        properties: {
          privateDnsZoneId: privatednszone.id
        }
      }
    ]
  }
}
