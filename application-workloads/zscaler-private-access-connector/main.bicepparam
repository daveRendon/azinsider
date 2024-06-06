using 'main.bicep'

param networkInterfaceName = 'azinsider-zpa-nic1'

param enableAcceleratedNetworking = true

param networkSecurityGroupName = 'azinsider-zpa-nsg'

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
      priority: 320
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
]

param subnetName = 'default'

param virtualNetworkName = 'azinsider-zpa-vnet'

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

param publicIpAddressName = 'azinsider-zpa-pip'

param publicIpAddressType = 'Dynamic'

param publicIpAddressSku = 'Basic'

param pipDeleteOption = 'Detach'

param vmName = 'azinsider-zpa-vm'

param osDiskType = 'Standard_LRS'

param osDiskDeleteOption = 'Delete'

param virtualMachineSize = 'Standard_D2as_v4'

param nicDeleteOption = 'Detach'

param adminUsername = 'azureuser'

param adminPassword = 'YOUR-ADMIN-PASSWORD'
