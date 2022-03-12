param appPlanPrefix string
param sku string = 'S1' // The SKU of App Service Plan
param location string = 'eastus' // Location for all resources

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  //interpolate param
  name: 'AppPlan-${appPlanPrefix}'
  //pass on location param
  location: location
  kind: 'windows'
  sku: {
    //pass on sku param
    name: sku
  }
  
}
// Set an output which can be accessed by the module consumer
output appServicePlanId string = appServicePlan.id
