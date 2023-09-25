// App Service Plan Parameters
param appServicePlanName string
param appServicePlanSku string
param appServicePlanSkuCode string
param workerSize int
param workerSizeId int
param location string = resourceGroup().location


// Web App Parameters
param webAppName string

// Virtual Network Parameters
param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
}

resource privatednszone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.azurewebsites.net'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku
    tier: appServicePlanSkuCode
  }
  properties: {
    targetWorkerCount: workerSize
    targetWorkerSizeId: workerSizeId
  }
}

resource webApp 'Microsoft.Web/sites@2021-01-15' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: '5'
      alwaysOn: true
    }
  }
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2021-01-15' = {
  parent: webApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, virtualNetwork.properties.subnets[2].name)
    swiftSupported: true
  }
}

resource routingConfig 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: webApp
  name: 'web'
  properties: {
    vnetRouteAllEnabled: true
  }
}

resource privateendpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  dependsOn: [
    virtualNetwork
    webApp
  ]
  name: '${webAppName}-privateendpoint'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${webAppName}-peconnection'
        properties: {
          privateLinkServiceId: webApp.id
          groupIds: [
            'sites'
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
    webApp
    privatednszone
  ]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privatednszone.id
        }
      }
    ]
  }
}

output privateendpointnicname string = split(privateendpoint.properties.networkInterfaces[0].id, '/')[8]
output customDomainVerificationId string = webApp.properties.customDomainVerificationId
