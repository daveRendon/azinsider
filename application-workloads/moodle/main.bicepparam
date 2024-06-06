using 'main.bicep'

param location = 'eastus'

param networkInterfaceName = 'azinsidermoodle304'

param networkSecurityGroupName = 'azinsidermoodle-nsg'

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

param virtualNetworkName = 'azinsidermoodle_group-vnet'

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

param publicIpAddressName = 'azinsidermoodle-ip'

param publicIpAddressType = 'Dynamic'

param publicIpAddressSku = 'Basic'

param virtualMachineName = 'YOUR-VM-NAME'

param virtualMachineComputerName = 'YOUR-VM-COMPUTER-NAME'

param osDiskType = 'StandardSSD_LRS'

param virtualMachineSize = 'Standard_D2as_v4'

param adminUsername = 'YOUR_ADMIN_USERNAME'

param adminPassword = 'YOUR_PASSWORD'
