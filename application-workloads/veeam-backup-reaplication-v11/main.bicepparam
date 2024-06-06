using 'main.bicep'

param location = 'eastus'

param networkInterfaceName = 'azinsider-nic'

param networkSecurityGroupName = 'azinsider-nsg'

param networkSecurityGroupRules = [
  {
    name: 'CloudConnect'
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
      destinationPortRange: '6180'
    }
  }
  {
    name: 'default-allow-rdp'
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
      destinationPortRange: '3389'
    }
  }
]

param subnetName = 'default'

param virtualNetworkName = 'azinsider-demo-vnet'

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

param osDiskType = 'Premium_LRS'

param osDiskDeleteOption = 'Delete'

param virtualMachineSize = 'Standard_D2as_v4'

param nicDeleteOption = 'Detach'

param adminUsername = 'azureuser'

param adminPassword = 'YOUR-ADMIN-PASSWD'

param patchMode = 'AutomaticByOS'

param enableHotpatching = false
