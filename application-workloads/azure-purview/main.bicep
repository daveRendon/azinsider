@description('Name of the resource')
param purviewname string

@description('Deployment region')
param location string

@description('Deployment environment')
param env string

resource purviewname_env 'Microsoft.Purview/accounts@2021-07-01' = {
  name: '${purviewname}${env}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  
  tags: {}
  dependsOn: []
}
