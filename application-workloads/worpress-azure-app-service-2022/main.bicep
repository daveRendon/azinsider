param subscriptionId string
param name string
param location string
param hostingPlanName string
param serverFarmResourceGroup string
param sku string
param skuCode string
param workerSize string
param workerSizeId string
param numberOfWorkers string
param kind string
param reserved bool
param alwaysOn bool
param linuxFxVersion string
param dockerRegistryUrl string
param storageSizeGB int
param storageIops int
param storageAutoGrow string
param backupRetentionDays int
param geoRedundantBackup string
param charset string
param collation string
param vmName string
param serverEdition string
param vCores int
param serverName string
param serverUsername string

@secure()
param serverPassword string
param databaseName string
param publicNetworkAccess string
param wordpressTitle string
param wordpressAdminEmail string
param wordpressUsername string

@secure()
param wordpressPassword string
param wpLocaleCode string
param cdnProfileName string
param cdnEndpointName string
param cdnType string
param cdnEndpointProperties object
param vnetName string
param subnetForApp string
param subnetForDb string
param privateDnsZoneNameForDb string

var appServicesApiVersion = '2021-03-01'
var databaseApiVersion = '2021-05-01'
var databaseVersion = '5.7'
var vnetDeploymentApiVersion = '2020-07-01'
var privateDnsApiVersion = '2018-09-01'
var privateEndpointApiVersion = '2021-03-01'
var vnetAddress = '10.0.0.0/16'
var subnetAddressForApp = '10.0.0.0/24'
var subnetAddressForDb = '10.0.1.0/24'
var cdnApiVersion = '2020-04-15'

resource name_resource 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  tags: null
  properties: {
    name: name
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: dockerRegistryUrl
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'true'
        }
        {
          name: 'DATABASE_HOST'
          value: '${serverName}.mysql.database.azure.com'
        }
        {
          name: 'DATABASE_NAME'
          value: databaseName
        }
        {
          name: 'DATABASE_USERNAME'
          value: serverUsername
        }
        {
          name: 'DATABASE_PASSWORD'
          value: serverPassword
        }
        {
          name: 'WORDPRESS_ADMIN_EMAIL'
          value: wordpressAdminEmail
        }
        {
          name: 'WORDPRESS_ADMIN_USER'
          value: wordpressUsername
        }
        {
          name: 'WORDPRESS_ADMIN_PASSWORD'
          value: wordpressPassword
        }
        {
          name: 'WORDPRESS_TITLE'
          value: wordpressTitle
        }
        {
          name: 'WEBSITES_CONTAINER_START_TIME_LIMIT'
          value: '900'
        }
        {
          name: 'WORDPRESS_LOCALE_CODE'
          value: wpLocaleCode
        }
        {
          name: 'SETUP_PHPMYADMIN'
          value: 'true'
        }
        {
          name: 'CDN_ENABLED'
          value: 'true'
        }
        {
          name: 'CDN_ENDPOINT'
          value: '${cdnEndpointName}.azureedge.net'
        }
      ]
      connectionStrings: []
      linuxFxVersion: linuxFxVersion
      vnetRouteAllEnabled: true
    }
    serverFarmId: '/subscriptions/${subscriptionId}/resourcegroups/${serverFarmResourceGroup}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
    clientAffinityEnabled: false
  }
  dependsOn: [
    hostingPlanName_resource
    serverName_resource
    serverName_databaseName
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  kind: kind
  tags: null
  properties: {
    name: hostingPlanName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    reserved: reserved
  }
  sku: {
    Tier: sku
    Name: skuCode
  }
  dependsOn: [
    serverName_resource
  ]
}

resource serverName_resource 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' = {
  location: location
  name: serverName
  tags: {
    AppProfile: 'Wordpress'
  }
  properties: {
    version: databaseVersion
    administratorLogin: serverUsername
    administratorLoginPassword: serverPassword
    publicNetworkAccess: publicNetworkAccess
    Storage: {
      StorageSizeGB: storageSizeGB
      Iops: storageIops
      Autogrow: storageAutoGrow
    }
    Backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    Network: {
      PrivateDnsZoneResourceId: privateDnsZoneNameForDb_resource.id
      DelegatedSubnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetForDb)
    }
  }
  sku: {
    name: vmName
    tier: serverEdition
    capacity: vCores
  }
  dependsOn: [
    privateDnsZoneNameForDb_privateDnsZoneNameForDb_vnetlink
  ]
}

resource serverName_databaseName 'Microsoft.DBforMySQL/flexibleServers/databases@2021-05-01' = {
  name: '${serverName}/${databaseName}'
  properties: {
    charset: charset
    collation: collation
  }
  dependsOn: [
    serverName_resource
  ]
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  location: location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: subnetForApp
        properties: {
          addressPrefix: subnetAddressForApp
          delegations: [
            {
              name: 'dlg-appService'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: subnetForDb
        properties: {
          addressPrefix: subnetAddressForDb
          delegations: [
            {
              name: 'dlg-database'
              properties: {
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
  dependsOn: []
}

resource privateDnsZoneNameForDb_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneNameForDb
  location: 'global'
  dependsOn: []
}

resource privateDnsZoneNameForDb_privateDnsZoneNameForDb_vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZoneNameForDb}/${privateDnsZoneNameForDb}-vnetlink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetName_resource.id
    }
    registrationEnabled: true
  }
  dependsOn: [
    privateDnsZoneNameForDb_resource

  ]
}

resource name_virtualNetwork 'Microsoft.Web/sites/networkConfig@2021-03-01' = {
  name: '${name}/virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetForApp)
  }
  dependsOn: [
    name_resource
    privateDnsZoneNameForDb_privateDnsZoneNameForDb_vnetlink
  ]
}

resource name_web 'Microsoft.Web/sites/config@2021-03-01' = {
  name: '${name}/web'
  properties: {
    alwaysOn: alwaysOn
  }
  dependsOn: [
    name_resource
    name_virtualNetwork
  ]
}

resource cdnProfileName_resource 'Microsoft.Cdn/profiles@2020-04-15' = {
  name: cdnProfileName
  location: 'Global'
  sku: {
    name: cdnType
  }
  tags: {
    AppProfile: 'Wordpress'
  }
  properties: {
  }
  dependsOn: [
    serverName_resource
  ]
}

resource cdnProfileName_cdnEndPointName 'Microsoft.Cdn/profiles/endpoints@2020-04-15' = {
  name: '${cdnProfileName}/${cdnEndpointName}'
  location: 'Global'
  properties: cdnEndpointProperties
  dependsOn: [
    cdnProfileName_resource
    name_resource
  ]
}
