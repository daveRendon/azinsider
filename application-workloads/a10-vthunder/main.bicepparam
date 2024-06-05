using 'main.bicep'

param networkInterfaceName1 = 'azinsider-nic1'

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
    name: 'HTTPS'
    properties: {
      priority: 310
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
]

param subnetName = 'default'

param virtualNetworkName = 'azinsider_demo-vnet'

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

param publicIpAddressName1 = 'azinsider-ip'

param publicIpAddressType = 'Static'

param publicIpAddressSku = 'Standard'

param pipDeleteOption = 'Detach'

param virtualMachineName = 'azinsider'

param osDiskType = 'StandardSSD_LRS'

param osDiskDeleteOption = 'Delete'

param virtualMachineSize = 'Standard_D2as_v4'

param nicDeleteOption = 'Detach'

param adminUsername = 'Your-admin-username'

param authenticationType = 'password'

param adminPassword = 'SSH-key-or-Password'
