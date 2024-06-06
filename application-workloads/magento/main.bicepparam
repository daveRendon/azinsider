using 'main.bicep'

param location = 'eastus'

param networkInterfaceName = 'vm-magento684'

param networkSecurityGroupName = 'vm-magento-nsg'

param networkSecurityGroupRules = [
  {
    name: 'HTTP'
    properties: {
      priority: 1010
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceApplicationSecurityGroups: []
      destinationApplicationSecurityGroups: []
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
    }
  }
  {
    name: 'HTTPS'
    properties: {
      priority: 1020
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceApplicationSecurityGroups: []
      destinationApplicationSecurityGroups: []
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
  {
    name: 'SSH'
    properties: {
      priority: 1030
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceApplicationSecurityGroups: []
      destinationApplicationSecurityGroups: []
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
    }
  }
]

param subnetName = 'default'

param virtualNetworkName = 'magento-vnet'

param addressPrefixes = [
  '10.0.0.0/16'
]

param subnets = [
  {
    name: 'default'
    properties: {
      addressPrefix: '10.0.0.0/24'
    }
  }
]

param publicIpAddressName = 'vm-magento-ip'

param publicIpAddressType = 'Dynamic'

param publicIpAddressSku = 'Basic'

param virtualMachineName = 'vm-magento'

param virtualMachineComputerName = 'vm-magento'

param osDiskType = 'StandardSSD_LRS'

param virtualMachineSize = 'Standard_D2as_v4'

param adminUsername = 'your-admin-username'

param adminPassword = null
