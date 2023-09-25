
param suffix string = 'azinsider'
param usePreviewFeatures bool = true

//Vnet
param virtualNetworkName string = 'vnet-${suffix}'
param addressSpace string = '10.235.235.0/24'
param firewallSubnet string = '10.235.235.0/26'
param privateLinkSubnet string = '10.235.235.64/27'
param webAppSubnet string = '10.235.235.96/27'

// Network Security Group
param nsgName string = 'nsg${suffix}'

// Azure Firewall 
param firewallIpName string = 'firewallip${suffix}'
param firewallName string = 'firewall${suffix}'

// Web App 
param webAppName string = 'webapp${suffix}'

// App Service Plan 
param appServicePlanName string = 'appsp${suffix}'
param appServicePlanSku string = 'S1'
param appServicePlanSkuCode string = 'S'
param workerSize int = 0
param workerSizeId int = 0

// Front Door 

param frontDoorName string = 'frontdoor${suffix}'
param customBackendFqdn string

// SQL 
param sqlName string = 'sql${suffix}'
param sqlAdministratorLogin string = 'sql${suffix}admin'
@secure()
param sqladministratorLoginPassword string 

// Route Table name
param routeTableName string = 'routetable${suffix}'

module nsgDeployment './modules/nsg.bicep' = if(usePreviewFeatures){
  name: 'nsgDeployment'
  params: {
    nsgName: nsgName
    securityRules: [
      {
        ruleName: 'Allow-Firewall'
        description: 'Allow Firewall subnet'
        access: 'Allow'
        protocol: '*'
        direction: 'Inbound'
        priority: 100
        sourceAddressPrefix: '10.235.235.0/26'
        sourcePortRange: '*'
        destinationAddressPrefix: '10.235.235.64/27'
        destinationPortRange: '*'
      }
    ]
  }
}
module networkDeployment './modules/network.bicep' = {
  dependsOn: [
    nsgDeployment
  ]
  name: 'networkDeployment'
  params: {
    addressSpace: addressSpace
    firewallIpName: firewallIpName
    firewallSubnet: firewallSubnet
    privateLinkSubnet: privateLinkSubnet
    virtualNetworkName: virtualNetworkName
    webAppSubnet: webAppSubnet
    usePreviewFeatures: usePreviewFeatures
    nsgName: usePreviewFeatures ? nsgName : ''
  }
}

module webappDeployment './modules/webapp.bicep' = {
  dependsOn: [
    networkDeployment
  ]
  name: 'webappDeployment'
  params: {
    appServicePlanName: appServicePlanName
    appServicePlanSku: appServicePlanSku
    appServicePlanSkuCode: appServicePlanSkuCode
    virtualNetworkName: virtualNetworkName
    webAppName: webAppName
    workerSize: workerSize
    workerSizeId: workerSizeId
  }
}

module firewallDeployment './modules/firewall.bicep' = {
  dependsOn: [
    networkDeployment
    webappDeployment
  ]
  name: 'firewallDeployment'
  params: {
    firewallIpName: firewallIpName
    firewallName: firewallName
    privateendpointnicname: webappDeployment.outputs.privateendpointnicname
    virtualNetworkName: virtualNetworkName
    webAppName: webAppName
  }
}

module frontDoorDeployment './modules/frontdoor.bicep' = {
  name: 'frontDoorDeployment'
  params: {
    customBackendFqdn: customBackendFqdn
    frontDoorName: frontDoorName
  }
}

module sqlDeployment './modules/sql.bicep' = {
  dependsOn: [
    networkDeployment
  ]
  name: 'sqlDeployment'
  params: {
    sqlAdministratorLogin: sqlAdministratorLogin
    sqladministratorLoginPassword: sqladministratorLoginPassword
    sqlName: sqlName
    virtualNetworkName: virtualNetworkName
  }
}

module routingDeployment './modules/routetable.bicep' = {
  dependsOn: [
    networkDeployment
    webappDeployment
    firewallDeployment
  ]
  name: 'routingDeployment'
  params: {
    firewallName: firewallName
    routetablename: routeTableName
    virtualNetworkName: virtualNetworkName
    webAppSubnet: webAppSubnet
  }
}

output firewallPublicIp string = firewallDeployment.outputs.firewallPublicIp
output customDomainVerificationId string = webappDeployment.outputs.customDomainVerificationId
output sqlFqdn string = '${sqlName}.database.windows.net'
