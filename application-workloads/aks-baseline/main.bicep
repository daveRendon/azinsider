targetScope='subscription'

param rgHubVnetName string = 'rg-enterprise-networking-hubs'
param rgHubVnetLocation string = 'centralus'

param rgSpokeVnetName string = 'rg-enterprise-networking-spokes'
param rgSpokeVnetLocation string = 'centralus'

//This resource group will be the parent group for the application
param rgAppName string = 'rg-bu0001a0008'
param rgAppLocation string = 'eastus2'

resource rgHubVnet 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgHubVnetName
  location: rgHubVnetLocation
}

resource rgSpokeVnet 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgSpokeVnetName
  location: rgSpokeVnetLocation
}

resource rgApp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgAppName
  location: rgAppLocation
}
