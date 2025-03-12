using './main.bicep'

param addressPrefixes = [
  '10.17.0.0/16'
]

param subnets = [
  {
    name: 'snet-eastus-1'
    properties: {
      addressPrefixes: [
        '10.17.0.0/24'
      ]
      ipamPoolPrefixAllocations: []
    }
  }
]

param virtualNetworkName = 'vnet-eastus-1'

param networkSecurityGroupName = 'basicNsgvnet-eastus-1-nic01'

param location = 'eastus'

param securityRules = []

param name = 'azinsider-compute-fleet'

param licenseType = 'None'

param zones = []

param sizes = [
  {
    name: 'Standard_B4ms'
  }
  {
    name: 'Standard_D2s_v3'
  }
  {
    name: 'Standard_DS3_v2'
  }
]

param userName = 'azureuser'

param password = 'Your-Password-Here'

param regularTargetCapacity = '5'

param regularMinCapacity = '0'

param regularAllocationStrategy = 'LowestPrice'

param networkInterfaceConfigurationName = 'vnet-eastus-1-nic01'
