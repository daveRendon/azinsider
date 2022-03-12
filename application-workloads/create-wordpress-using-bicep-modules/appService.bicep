param appServicePrefix string
param location string = 'eastus'
param appServicePlanId string
param repoUrl string = 'https://github.com/daveRendon/wordpress-azure/'

resource appService 'Microsoft.Web/sites@2021-03-01' = {
  name: '${appServicePrefix}-site'
  location: location
  properties:{
    serverFarmId: appServicePlanId
    siteConfig: {
      minTlsVersion: '1.2'
      localMySqlEnabled: true
      appSettings: [
        {
          name: 'WEBSITE_MYSQL_ENABLED'
          value: '1'
        }
        {
          name: 'WEBSITE_MYSQL_GENERAL_LOG'
          value: '0'
        }
        {
          name: 'WEBSITE_MYSQL_SLOW_QUERY_LOG'
          value: '0'
        }
        {
          name: 'WEBSITE_MYSQL_ARGUMENTS'
          value: '--max_allowed_packet=16M'
        }
      ]
    }
    
  }
}

resource appConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: appService
  name: 'web'
  properties: {
    phpVersion: '7.4'
  }
}

resource sourceControls 'Microsoft.Web/sites/sourcecontrols@2021-03-01' = {
  name: 'web'
  parent: appService
  properties: {
    repoUrl: repoUrl
    branch: 'master'
    isManualIntegration: true
  }
}

// Set an output which can be accessed by the module consumer
output siteURL string = appService.properties.hostNames[0]
