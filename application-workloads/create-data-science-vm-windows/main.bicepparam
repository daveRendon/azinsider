using 'main.bicep'

param location = 'eastus'

param networkInterfaceName = 'azinsider-dsvm468'

param networkSecurityGroupName = 'azinsider-dsvm-nsg'

param networkSecurityGroupRules = [
  {
    name: 'RDP'
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
      destinationPortRange: '3389'
    }
  }
  {
    name: 'SSH'
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
      destinationPortRange: '22'
    }
  }
]

param subnetName = 'default'

param virtualNetworkName = 'tst-vnet'

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

param publicIpAddressName = 'azinsider-dsvm-ip'

param publicIpAddressType = 'Dynamic'

param publicIpAddressSku = 'Basic'

param virtualMachineName = 'azinsider-dsvm'

param virtualMachineComputerName = 'azinsider-dsvm'

param osDiskType = 'Standard_LRS'

param virtualMachineSize = 'Standard_D2as_v4'

param adminUsername = 'azureuser'

param adminPassword = 'AzureKemp01!!'

param patchMode = 'AutomaticByOS'

param enableHotpatching = false
