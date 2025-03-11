using './main.bicep' 

param vnetManagerName = 'azinsider-vnet-manager'

param location = 'eastus'

param tagsByResource = {}

param networkManagerScopes = {
  subscriptions: [
    '/subscriptions/your-subscription-id'
  ]
  managementGroups: []
}

param networkManagerScopeAccesses = [
  'Connectivity'
  'SecurityAdmin'
  'Routing'
  'SecurityUser'
]
