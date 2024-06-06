using 'main.bicep'

param networkInterfaceName = 'ubuntu-prometheus-gr653'

param networkSecurityGroupName = 'ubuntu-prometheus-grafana-nsg'

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
    name: 'Prometheus'
    properties: {
      priority: 310
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '9090'
    }
  }
  {
    name: 'Grafana'
    properties: {
      priority: 320
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3000'
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

param publicIpAddressName = 'ubuntu-prometheus-grafana-ip'

param publicIpAddressType = 'Static'

param publicIpAddressSku = 'Standard'

param virtualMachineName = 'ubuntu-prometheus-grafana'

param virtualMachineComputerName = 'ubuntu-prometheus-grafana'

param osDiskType = 'StandardSSD_LRS'

param virtualMachineSize = 'Standard_B4ms'

param adminUsername = 'Your-VM-admin-username'

param adminPassword = 'Your-Password-or-SSH-Key'

param zone = '1'
