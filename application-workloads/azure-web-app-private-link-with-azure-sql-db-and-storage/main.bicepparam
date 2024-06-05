using 'main.bicep'

param vNets = [
  {
    name: 'hub-vnet'
    addressPrefixes: [
      '10.1.0.0/16'
    ]
    subnets: [
      {
        name: 'PrivateLinkSubnet'
        addressPrefix: '10.1.1.0/24'
        udrName: null
        nsgName: null
        delegations: null
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
  {
    name: 'spoke-vnet'
    addressPrefixes: [
      '10.2.0.0/16'
    ]
    subnets: [
      {
        name: 'AppSvcSubnet'
        addressPrefix: '10.2.1.0/24'
        udrName: null
        nsgName: null
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        delegations: [
          {
            name: 'appservice'
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
          }
        ]
      }
    ]
  }
]

param sqlAdministratorLoginName = 'YOUR-SQL-ADMIN-USERNAME'

param sqlAdministratorLoginPassword = 'YOUR-SQL-ADMIN-PASS'
