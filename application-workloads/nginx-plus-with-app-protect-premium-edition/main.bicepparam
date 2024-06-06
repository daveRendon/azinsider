using 'main.bicep'

param location = 'eastus'

param networkInterfaceName = 'azinsider-nic1'

param enableAcceleratedNetworking = true

param networkSecurityGroupName = 'azinsider-nsg'

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

param vmName = 'azinsider'

param osDiskType = 'Premium_LRS'

param osDiskDeleteOption = 'Delete'

param virtualMachineSize = 'Standard_D2as_v4'

param nicDeleteOption = 'Detach'

param adminUsername = 'azureuser'

param adminPassword = 'YOUR-ADMIN-PASSWD'
