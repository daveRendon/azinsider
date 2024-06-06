using 'main.bicep'

param networkInterfaceName = 'azinsider-nic1'

param networkSecurityGroupName = 'azinsider-nsg'

param networkSecurityGroupRules = [
  {
    name: 'SSH'
    properties: {
      priority: 300
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
    }
  }
  {
    name: 'HTTP'
    properties: {
      priority: 320
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
    }
  }
  {
    name: 'HTTPS'
    properties: {
      priority: 340
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
  {
    name: 'MGMT'
    properties: {
      priority: 350
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '8443'
    }
  }
]

param subnetName = 'default'

param virtualNetworkName = 'azinsider-vnet'

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

param publicIpAddressName = 'azinsider-ip'

param publicIpAddressType = 'Dynamic'

param publicIpAddressSku = 'Basic'

param pipDeleteOption = 'Detach'

param virtualMachineName = 'azinsider'

param osDiskType = 'StandardSSD_LRS'

param osDiskDeleteOption = 'Delete'

param virtualMachineSize = 'Standard_D2as_v4'

param nicDeleteOption = 'Detach'

param adminUsername = 'azinsider'

param adminPassword = 'YOUR-ADMIN-PASS'
