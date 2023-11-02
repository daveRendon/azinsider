// Parameters
param rgname string = 'azinsider_demo'
param location string = 'eastus'
param vnetAddressPrefix string = '10.0.0.0/16'
param existentVnetName string = ''
param aseSubnet string = '10.0.100.0/24'
param fwSubnet string = '10.0.200.0/24'
param jumpboxSubnet string = '10.0.250.0/24'
param servicesSubnet string = '10.0.50.0/24'
param redisSubnet string = '10.0.2.0/24'
param appGtwySubnet string = '10.0.1.0/24'
param subnet1Name string = 'ase-subnet'
param subnet2Name string = 'AzureFirewallSubnet'
param subnet3Name string = 'jumpbox-subnet'
param subnet4Name string = 'redis-subnet'
param subnet5Name string = 'services-subnet'

param redisSubnetAddressPrefix string
param aseName string
param aseDnsSuffix string
param keyVaultName string
param servicesSubnetAddressPrefix string
param sbName string
param sqlServerName string
param sqlDatabaseName string
param sqlAdminUserName string
param appGwSubnetAddressWithPrefix string
param subId string
param adminPassword string
param cosmosDbName string
param sqlName string
param sqlAdminPassword string
param allowedSubnetNames string

@description('Required. Dedicated host count of ASEv3.')
param dedicatedHostCount int = 0

@description('Required. Zone redundant of ASEv3.')
param zoneRedundant bool = false

//App url
param appGtwyApp1Url string = 'votingapp-std.contoso.com'
param appGtwyApp2Url string = 'testapp-std.contoso.com'

param jumpboxUsername string = 'azureuser'

param sqlAdminuser string = 'azureuser'
@secure()
param sqlPassword string 
param sqlAadAdminSid string = '5b4c9cef-f232-4184-8ecf-a61f3545edc8' // get this value from the Azure AD user object or using the following command: az ad signed-in-user show --query id -o tsv

var subscriptionId = subscription().subscriptionId
var mustCreateVNet = empty(existentVnetName)
param vnetName string = (empty(existentVnetName) ? 'ase-vnet' : existentVnetName)
var vnetRouteName = 'ase-vnet-route'

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = if (mustCreateVNet) {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: aseSubnet
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: fwSubnet
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: jumpboxSubnet
        }
      }
      {
        name: subnet4Name
        properties: {
          addressPrefix: redisSubnet
        }
      }
      {
        name: subnet5Name
        properties: {
          addressPrefix: servicesSubnet
        }
      }
    ]
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

module ase 'modules/ase.bicep' = {
  name: 'ase'
  dependsOn: [
    jumpbox
  ]
  scope: resourceGroup(rgname)
  params:{
    location: location
    aseSubnetAddressPrefix: aseSubnet
    vnetName: vnet.name
    vnetRouteName: vnetRoute.name
  }
}

module firewall 'modules/firewall.bicep' = {
  name: 'firewall'
  dependsOn: [
    ase
  ]
  scope: resourceGroup(rgname)
  params: {
    location: location
    vnetName: vnetName
    firewallSubnetPrefix: fwSubnet
  }
}

module dns 'modules/dns.bicep' = {
  name: 'dns'
  dependsOn: [
    ase
  ]
  scope: resourceGroup(rgname)
  params: {
    vnetName: vnetName
    ipAddress: ase.outputs.aseIlbIp
    zoneName: ase.outputs.dnsSuffix
  }
}

module jumpbox 'modules/jumpbox.bicep' = {
  name: 'jumpbox'
  dependsOn: [
    vnet
  ]
  params: {
    location: location
    adminPassword: adminPassword
    adminUsername: jumpboxUsername
    jumpboxSubnetAddressPrefix: jumpboxSubnet
    vnetName: vnet.name
  }
}

module services 'modules/services.bicep' = {
  name: 'services'
  dependsOn: [
    ase
  ]
  params: {
    location: location
    allowedSubnetNames: ase.outputs.aseSubnetName
    sqlAadAdminSid: sqlAadAdminSid
    sqlAdminPassword: sqlPassword
    sqlAdminUserName: sqlAdminuser
    vnetName: vnet.name
  }
}

module sites 'modules/sites.bicep' = {
  name: 'sites'
  dependsOn: [
    services
  ]
  params: {
    location: location
    aseDnsSuffix: ase.outputs.dnsSuffix
    aseName: ase.name
    cosmosDbName: services.outputs.cosmosDbName
    keyVaultName: services.outputs.keyVaultName
    redisSubnetAddressPrefix: redisSubnet
    sqlDatabaseName: services.outputs.sqlDatabaseName
    sqlServerName: services.outputs.sqlServerName
    vnetName: vnetName
  }
}

module appGtwy 'modules/appgw.bicep' = {
  name: 'appGtwy'
  dependsOn: [
    sites
  ]
  params: {
    location: location
    appgwApplications: [
      {
        name: 'votapp'
        routingPriority: 100
        hostName: appGtwyApp1Url
        backendAddresses: [
          {
            fqdn: sites.outputs.votingAppUrl
          }
        ]
        
        //certificate: {
         // data: ''
         // password: ''
       // }
        probePath: '/health'
      }
      {
        name: 'testapp'
        routingPriority: 101
        hostName: appGtwyApp2Url
        backendAddresses: [
          {
            fqdn: sites.outputs.testAppUrl
          }
        ]
        //certificate: {
        //  data: ''
        //  password: ''
       // }
        probePath: '/'
      }
    ]
    appGwSubnetAddressWithPrefix: appGtwySubnet
    vnetName: vnetName
  }
}

module endpoints 'modules/privateendpoints.bicep' = {
  name: 'endpoints'
  dependsOn: [
    appGtwy
  ]
  params: {
    location: location
    keyVaultName: services.outputs.keyVaultName
    cosmosDBName: services.outputs.cosmosDbName
    sbName: services.outputs.serviceBusName
    sqlName: services.outputs.sqlServerName
    SubId: subscriptionId
    servicesSubnetAddressPrefix: servicesSubnet
    vnetName: vnetName
  }
}

output vnetName string = vnet.name
output vnetRouteName string = vnetRoute.name
output asename string = ase.name
output aseSubnetName string = ase.outputs.aseSubnetName
output firewallname string = firewall.name
output aseDnsSuffix string = ase.outputs.dnsSuffix
output aseDnsIlbIpAddress string = ase.outputs.aseIlbIp
output jumpboxPublicIpAddress string = jumpbox.outputs.jumpboxPublicIpAddress
output jumpboxSubnetName string = jumpbox.outputs.jumpboxSubnetName
output cosmosDbName string = services.outputs.cosmosDbName
output sqlServerName string = services.outputs.sqlServerName
output sqlDatabaseName string = services.outputs.sqlDatabaseName
output keyVaultName string = services.outputs.keyVaultName
output storageAccountName string = services.outputs.resourcesStorageAccountName
output cotainerRegistryName string = services.outputs.resourcesContainerName
output serviceBusName string = services.outputs.serviceBusName
output internalApp1URL string = sites.outputs.votingAppUrl
output internalApp2URL string = sites.outputs.testAppUrl
output votingWebaAppPrincipalId string = sites.outputs.votingWebAppIdentityPrincipalId
output votingCounterFunctionName string = sites.outputs.votingFunctionName
output votingCounterFunctionPrincipalId string = sites.outputs.votingCounterFunctionIdentityPrincipalId
output votingAPIName string = sites.outputs.votingApiName
output votingAPIPrincipalId string = sites.outputs.votingApiIdentityPrincipalId
output appGtwyName string = appGtwy.name
output appGtwyPublicIpAddress string = appGtwy.outputs.appGwPublicIpAddress
