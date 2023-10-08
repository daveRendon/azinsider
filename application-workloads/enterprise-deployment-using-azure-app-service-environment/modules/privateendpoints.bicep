//param privateEndpoints_votingsbpe_name string = 'votingsbpe'

@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('Subscrpition ID')
param SubId string

@description('The name of the existing vnet to use.')
param vnetName string

@description('The name of the existing service bus namespace for creating the private endpoint.')
param sbName string

@description('The name of the existing sql server namespace for creating the private endpoint.')
param sqlName string

@description('The name of the existing cosmosdb namespace for creating the private endpoint.')
param cosmosDBName string

@description('The name of the existing keyvault namespace for creating the private endpoint.')
param akvName string

@description('The ip address prefix that services subnet will use.')
param subnetAddressPrefix string

var servicesSubnetName = 'services-subnet-${uniqueString(resourceGroup().id)}'
var servicesNSGName = '${vnetName}-SERVICES-NSG'

var vnetId = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnetName}'
// var subnetId = '${vnetId}/subnets/${servicesSubnetName}'

param sbId string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ServiceBus/namespaces/${sbName}'
param sqlServerId string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Sql/servers/${sqlName}'
param cosmosId string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDBName}'
param akvId string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.KeyVault/vaults/${akvName}'


//1. Create a private endpoint for the SQL Server

//Create variables for the private endpoint
var privateEndpointSQLName = 'voting-SQL-PE-${servicesSubnetName}'
var privateDnsZoneSQLName = 'privatelink${environment().suffixes.sqlServerHostname}'
var pvtEndpointDnsGroupSQLName = '${privateEndpointSQLName}/sqldnsgroupname'

//Create an NSG for the subnet
resource servicesNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: servicesNSGName
  location: location
  tags: {
    displayName: servicesNSGName
  }
}

//Create a subnet for all private endpoints
resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${vnetName}/${servicesSubnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: servicesNSG.id
    }
  }
}

//Create the private endpoint
resource privateEndpointSQL 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointSQLName
  location: location
  properties: {
    customNetworkInterfaceName: '${privateEndpointSQLName}-nic'
    subnet: {
      id: servicesSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointSQLName
        properties: {
          privateLinkServiceId: sqlServerId
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneSQL 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneSQLName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLinkSQL 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneSQL
  name: '${privateDnsZoneSQLName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource pvtEndpointDnsGroupSQL 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupSQLName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneSQL.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSQL
  ]
}

resource privateDnsZoneARecordSQL 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZoneSQL
  name: '${privateEndpointSQLName}.${privateDnsZoneSQLName}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpointSQL.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

//2. Create a private endpoint for the Service Bus

//Create variables for the private endpoint
var serviceBusHostName = '.servicebus.windows.net'
var privateEndpointSBName = 'voting-SB-PE-${servicesSubnetName}'
var privateDnsZoneSBName = 'privatelink${serviceBusHostName}'
var pvtEndpointDnsGroupSBName = '${privateEndpointSBName}/sbdnsgroupname'

//Create the private endpoint

resource privateEndpointSB 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointSBName
  location: location
  properties: {
    subnet: {
      id: servicesSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointSBName
        properties: {
          privateLinkServiceId: sbId
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneSB 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneSBName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLinkSB 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneSB
  name: '${privateDnsZoneSBName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource pvtEndpointDnsGroupSB 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupSBName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneSB.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointSB
  ]
}

resource privateDnsZoneARecordSB 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZoneSB
  name: '${privateEndpointSBName}.${privateDnsZoneSBName}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpointSB.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}



//3. Create a private endpoint for the Cosmos DB

//Create variables for the private endpoint
var cosmosDBHostName = '.documents.azure.com'
var privateEndpointCosmosName = 'voting-Cosmos-PE-${servicesSubnetName}'
var privateDnsZoneCosmosName = 'privatelink${cosmosDBHostName}'
var pvtEndpointDnsGroupCosmosName = '${privateEndpointCosmosName}/sbdnsgroupname'

//Create the private endpoint
resource privateEndpointCosmos 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointCosmosName
  location: location
  properties: {
    subnet: {
      id: servicesSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointCosmosName
        properties: {
          privateLinkServiceId: cosmosId
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneCosmos 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneCosmosName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLinkCosmos 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneCosmos
  name: '${privateDnsZoneCosmosName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource pvtEndpointDnsGroupCosmos 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupCosmosName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneCosmos.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointCosmos
  ]
}

resource privateDnsZoneARecordCosmos 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZoneCosmos
  name: '${privateEndpointCosmosName}.${privateDnsZoneCosmosName}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpointCosmos.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}





//4. Create a private endpoint for the Keyvault

//Create variables for the private endpoint
var akvHostName = '.vaultcore.azure.net'
var privateEndpointAKVName = 'voting-AKV-PE-${servicesSubnetName}'
var privateDnsZoneAKVName = 'privatelink${akvHostName}'
var pvtEndpointDnsGroupAKVName = '${privateEndpointAKVName}/sbdnsgroupname'

//Create the private endpoint
resource privateEndpointAKV 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointAKVName
  location: location
  properties: {
    subnet: {
      id: servicesSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointAKVName
        properties: {
          privateLinkServiceId: akvId
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneAKV 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneAKVName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLinkAKV 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneAKV
  name: '${privateDnsZoneAKVName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource pvtEndpointDnsGroupAKV 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupAKVName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneAKV.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointAKV
  ]
}

resource privateDnsZoneARecordAKV 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZoneAKV
  name: '${privateEndpointAKVName}.${privateDnsZoneAKVName}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpointAKV.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

