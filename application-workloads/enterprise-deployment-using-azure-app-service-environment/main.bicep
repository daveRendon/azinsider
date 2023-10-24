// Parameters
param rgname string = 'azinsider_demo'
param location string = 'eastus'
param vnetAddressPrefix string = '10.0.0.0/16'

@description('The name of the vnet to use. Leave empty to create a new vnet.')
param existentVnetName string = ''
param asePrefix string = '10.0.100.0/24'
param fwPrefix string = '10.0.200.0/24'

@description('Required. Dedicated host count of ASEv3.')
param dedicatedHostCount int = 0

@description('Required. Zone redundant of ASEv3.')
param zoneRedundant bool = false

//App url
param appGtwyApp1Url string = 'votingapp-std.contoso.com'
param appGtwyApp2Url string = 'testapp-std.contoso.com'

param jumpboxUsername string = 'azureuser'

@secure()
param jumpboxPassword string = 'P@ssword1234'
param jumpboxPrefix string = '10.0.250.0/24'

param sqlAdminuser string = 'azureuser'
param sqlPassword string = 'P@ssword1234'
param sqlAadAdminSid string = '5b4c9cef-f232-4184-8ecf-a61f3545edc8' // get this value from the Azure AD user object or using the following command: az ad signed-in-user show --query id -o tsv

param servicesPrefix string = '10.0.50.0/24'
param redisSubnet string = '10.0.2.0/24'
param appGtwySubnet string = '10.0.1.0/24'

var subscriptionId = subscription().subscriptionId
var mustCreateVNet = empty(existentVnetName)
var vnetName = (empty(existentVnetName) ? 'ASE-VNET-AzInsider' : existentVnetName)
var vnetRouteName = 'ASE-VNETRT-AzInsider'

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = if (mustCreateVNet) {
  name: vnetName
  location: location
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

module ase 'modules/ase.bicep' = {
  name: 'ase'
  dependsOn: [
    vnet
  ]
  scope: resourceGroup(rgname)
  params:{
    location: location
    aseSubnetAddressPrefix: asePrefix
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
    firewallSubnetPrefix: fwPrefix
  }
}

module dns 'modules/dns.bicep' = {
  name: 'dns'
  dependsOn: [
    firewall
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
    dns
  ]
  params: {
    location: location
    adminPassword: jumpboxUsername
    adminUsername: jumpboxPassword
    subnetAddressPrefix: jumpboxPrefix
    vnetName: vnet.name
  }
}

module services 'modules/services.bicep' = {
  name: 'services'
  dependsOn: [
    jumpbox
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
    subnetAddressWithPrefix: appGtwySubnet
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
    akvName: services.outputs.keyVaultName
    cosmosDBName: services.outputs.cosmosDbName
    sbName: services.outputs.serviceBusName
    sqlName: services.outputs.sqlServerName
    SubId: subscriptionId
    subnetAddressPrefix: servicesPrefix
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

