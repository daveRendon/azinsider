// Location for all resources
param location string = resourceGroup().location 
param prefix string

//consume appServicePlan as module
module appServicePlan 'appServicePlan.bicep' = {
  name:'appServicePlan'
  params: {
    appPlanPrefix: prefix
    location: location
  }
}

//consume appService as module
module appService 'appService.bicep' = {
  name: 'appService'
  params: {
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    appServicePrefix: prefix
    location: location
  }
}
