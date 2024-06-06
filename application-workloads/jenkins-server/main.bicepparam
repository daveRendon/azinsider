using 'main.bicep'

param location = 'eastus'

param networkInterfaceName = 'jenkinsvm109'

param networkSecurityGroupName = 'jenkinsvm-nsg'

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

param virtualNetworkName = 'YOUR-VNET-NAME'

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

param publicIpAddressName = 'PUBLIC-IP-NAME'

param publicIpAddressType = 'Dynamic'

param publicIpAddressSku = 'Basic'

param virtualMachineName = 'VM-NAME'

param virtualMachineComputerName = 'YOUR-VM-COMPUTER-NAME'

param osDiskType = 'Premium_LRS'

param virtualMachineSize = 'Standard_D2as_v4'

param adminUsername = 'YOUR-ADMIN-USERNAME'

param adminPassword = 'YOUR-PASSWORD'
