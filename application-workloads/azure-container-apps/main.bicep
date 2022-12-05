param name string
param location string
param environmentId string
param containers array

@secure()
param secrets object 
param registries array
param ingress object
param environmentName string
param workspaceName string
param workspaceLocation string

resource name_resource 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: name
  location: location
  properties: {
    environmentId: environmentId
    configuration: {
      secrets: secrets.arrayValue
      registries: registries
      activeRevisionsMode: 'Single'
      ingress: ingress
    }
    template: {
      containers: containers
      scale: {
        minReplicas: 0
      }
    }
  }
  dependsOn: [
    environment
  ]
}

resource environment 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference('Microsoft.OperationalInsights/workspaces/${workspaceName}', '2020-08-01').customerId
        sharedKey: listKeys('Microsoft.OperationalInsights/workspaces/${workspaceName}', '2020-08-01').primarySharedKey
      }
    }
  }
  sku: {
    name: 'Consumption'
  }
  dependsOn: [
    workspace
  ]
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: workspaceName
  location: workspaceLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
    }
  }
  dependsOn: []
}
