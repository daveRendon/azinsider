targetScope = 'subscription'
param mocOnPremResourceGroup string = 'site-to-site-mock-prem'
param azureNetworkResourceGroup string = 'site-to-site-azure-network'

@description(
  'The admin user name for both the Windows and Linux virtual machines.'
)
param adminUserName string

@description(
  'The admin password for both the Windows and Linux virtual machines.'
)
@secure()
param adminPassword string
param resourceGrouplocation string = 'eastus'

resource mocOnPremResourceGroup_resource 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: mocOnPremResourceGroup
  location: resourceGrouplocation
}

resource azureNetworkResourceGroup_resource 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: azureNetworkResourceGroup
  location: resourceGrouplocation
}

module onPrem 'modules/on-prem.bicep' = {
  name: 'onPrem'
  scope: resourceGroup(mocOnPremResourceGroup)
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    location: resourceGrouplocation
  }
  dependsOn: [mocOnPremResourceGroup_resource]
}

module azureNetwork 'modules/networking.bicep' = {
  name: 'azureNetwork'
  scope: resourceGroup(azureNetworkResourceGroup)
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    location: resourceGrouplocation
  }
  dependsOn: [azureNetworkResourceGroup_resource]
}

module mockOnPremLocalGateway 'modules/local-net-gtwy.bicep' = {
  name: 'mockOnPremLocalGateway'
  scope: resourceGroup(mocOnPremResourceGroup)
  params: {
    gatewayIpAddress: azureNetwork.outputs.vpnIp
    azureCloudVnetPrefix: azureNetwork.outputs.mocOnpremNetwork
    spokeNetworkAddressPrefix: azureNetwork.outputs.spokeNetworkAddressPrefix
    mocOnpremGatewayName: onPrem.outputs.mocOnpremGatewayName
    location: resourceGrouplocation
  }
}

module azureNetworkLocalGateway 'modules/azure-local-net-gtwy.bicep' = {
  name: 'azureNetworkLocalGateway'
  scope: resourceGroup(azureNetworkResourceGroup)
  params: {
    azureCloudVnetPrefix: onPrem.outputs.mocOnpremNetworkPrefix
    gatewayIpAddress: onPrem.outputs.vpnIp
    azureNetworkGatewayName: azureNetwork.outputs.azureGatewayName
    location: resourceGrouplocation
  }
}
