using 'main.bicep'

param networkInterfaceName = 'azinsider-barracudawaf-vm-nic'

param enableAcceleratedNetworking = true

param networkSecurityGroupName = 'azinsider-barracudawaf-vm-nsg'

param networkSecurityGroupRules = [
  {
    name: 'MGMT_HTTP'
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
      destinationPortRange: '8000'
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
    name: 'MGMT_HTTPS'
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
      destinationPortRange: '8443'
    }
  }
]

param subnetName = 'default'

param vnetName = 'azinsider-vnet'

param addressPrefixes = [
  '10.1.0.0/16'
]

param subnets = [
  {
    name: 'default'
    properties: {
      addressPrefix: '10.1.0.0/24'
    }
  }
]

param publicIpAddressName = 'azinsider-barracudawaf-vm-ip'

param publicIpAddressType = 'Dynamic'

param publicIpAddressSku = 'Basic'

param vmName = 'azinsider-barracudawaf-vm'

param osDiskType = 'StandardSSD_LRS'

param virtualMachineSize = 'Standard_D2as_v4'

param adminUsername = 'azureuser'

param adminPassword = 'YOUR-VM-PASSWORD'
