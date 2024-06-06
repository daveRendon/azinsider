using 'main.bicep'

param networkInterfaceName1 = 'azinsider-zscaler-nic1'

param enableAcceleratedNetworking = true

param networkSecurityGroupName = 'azinsider-zscaler-connector-nsg'

param networkSecurityGroupRules = [
  {
    name: 'ssh'
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
      destinationPortRange: '22'
    }
  }
  {
    name: 'https-outbound'
    properties: {
      priority: 1020
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Outbound'
      sourceApplicationSecurityGroups: []
      destinationApplicationSecurityGroups: []
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
]

param subnetName = 'default'

param vnetName = 'azinsider-zscaler-vnet'

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

param publicIpAddressName1 = 'azinsider-zscaler-pip'

param publicIpAddressType = 'Static'

param publicIpAddressSku = 'Standard'

param pipDeleteOption = 'Detach'

param vmName = 'azinsider-zscaler-connector'

param osDiskType = 'Standard_LRS'

param osDiskDeleteOption = 'Delete'

param vmSize = 'Standard_D2as_v4'

param nicDeleteOption = 'Detach'

param adminUsername = 'azureuser'

param adminPassword = 'YOUR-ADMIN-PASSWORD!!'

param zone = '1'
