@description('Location for all resources.')
param location string = resourceGroup().location

@description('Your source public IP address. Added to the inbound NSG on eth0 (MGMT)')
param srcIPInboundNSG string = '0.0.0.0/0'

@description('String passed down to the Virtual Machine.')
param customData string = 'echo customData'

@description('Name of VM-Series VM in the Azure portal')
param vmName string = 'VM-Series'

@description('Version number of VM-Series VM in the Azure portal')
@allowed([
  'latest'
  '10.1.0'
  '10.0.6'
  '9.1.10'
])
param imageVersion string = 'latest'

@description('Azure VM size for VM-Series')
@allowed([
  'Standard_D3_v2'
  'Standard_D4_v2'
])
param vmSize string = 'Standard_D3_v2'

@description('Name of the Virtual Network (VNET)')
param virtualNetworkName string = 'fwVNET'

@description('Use new or existing VNET')
@allowed([
  'new'
  'existing'
])
param vnetNewOrExisting string = 'new'

@description('Virtual network address CIDR')
param virtualNetworkAddressPrefixes array = array('192.168.0.0/16')

@description('Name of resource group of existing VNET (if applicable)')
param virtualNetworkExistingRGName string = ''

@description('Subnet for Management')
param subnet0Name string = 'Mgmt'

@description('Subnet for Untrust')
param subnet1Name string = 'Untrust'

@description('Subnet for Trust')
param subnet2Name string = 'Trust'

@description('Mgmt subnet CIDR')
param subnet0Prefix string = '192.168.0.0/24'

@description('Untrust subnet CIDR')
param subnet1Prefix string = '192.168.1.0/24'

@description('Trust subnet CIDR')
param subnet2Prefix string = '192.168.2.0/24'

@description('Untrust subnet start address')
param subnet1StartAddress string = '192.168.1.4'

@description('Trust subnet start address')
param subnet2StartAddress string = '192.168.2.4'

@description('Type of administrator user authentication ')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('Username of the administrator account of VM-Series')
param adminUsername string

@description('Password or ssh key for the administrator account of VM-Series.')
@secure()
param adminPasswordOrKey string

@description('Public IP for mgmt interface is new or existing')
@allowed([
  'new'
  'existing'
])
param publicIPNewOrExisting string = 'new'

@description('Name of existing public IP resource')
param publicIPAddressName string

@description('Name of existing public IP resource group')
param publicIPRGName string = 'None'

@description('Allocation method of public IP resource')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('Pass bootstrap data to VM')
@allowed([
  'yes'
  'no'
])
param bootstrap string = 'no'

@description('Availability Zone for VM-Series')
param zone string = 'None'
param availabilitySetName string = 'None'

var imagePublisher = 'paloaltonetworks'
var imageSku = 'byol'
var imageOffer = 'vmseries-flex'
var nsgName_var = 'DefaultNSG'
var nicName = '${vmName}-${publicIPAddressName}-eth'
var FWPrivateIPAddressUntrust = subnet1StartAddress
var FWPrivateIPAddressTrust = subnet2StartAddress
var existingVnetID = resourceId(virtualNetworkExistingRGName, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var existingSubnet0Ref = '${existingVnetID}/subnets/${subnet0Name}'
var existingSubnet1Ref = '${existingVnetID}/subnets/${subnet1Name}'
var existingSubnet2Ref = '${existingVnetID}/subnets/${subnet2Name}'
var newVnetID = virtualNetworkName_resource.id
var newSubnet0Ref = '${newVnetID}/subnets/${subnet0Name}'
var newSubnet1Ref = '${newVnetID}/subnets/${subnet1Name}'
var newSubnet2Ref = '${newVnetID}/subnets/${subnet2Name}'
var vnetID = ((vnetNewOrExisting == 'new') ? newVnetID : existingVnetID)
var subnet0Ref = ((vnetNewOrExisting == 'new') ? newSubnet0Ref : existingSubnet0Ref)
var subnet1Ref = ((vnetNewOrExisting == 'new') ? newSubnet1Ref : existingSubnet1Ref)
var subnet2Ref = ((vnetNewOrExisting == 'new') ? newSubnet2Ref : existingSubnet2Ref)
var virtualNetworkAddressPrefix = virtualNetworkAddressPrefixes[0]
var zones = [
  zone
]
var availabilitySet = {
  id: availabilitySetName_resource.id
}
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var subnets = [
  {
    name: subnet0Name
    properties: {
      addressPrefix: subnet0Prefix
      networkSecurityGroup: {
        id: nsgName.id
      }
    }
  }
  {
    name: subnet1Name
    properties: {
      addressPrefix: subnet1Prefix
    }
  }
  {
    name: subnet2Name
    properties: {
      addressPrefix: subnet2Prefix
    }
  }
]


resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-10-01' = if (publicIPNewOrExisting == 'new') {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: publicIPAddressName
    }
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2017-10-01' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Outside-From-IP'
        properties: {
          description: 'Rule'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: srcIPInboundNSG
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-Intra'
        properties: {
          description: 'Allow intra network traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: virtualNetworkAddressPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'Default-Deny'
        properties: {
          description: 'Default-Deny if we don\'t match Allow rule'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-10-01' = if (vnetNewOrExisting == 'new') {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: subnets
  }
}

resource nicName_0 'Microsoft.Network/networkInterfaces@2017-10-01' = {
  name: '${nicName}0'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-mgmt'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ((publicIPNewOrExisting == 'existing') ? resourceId(publicIPRGName, 'Microsoft.Network/publicIPAddresses', publicIPAddressName) : publicIPAddressName_resource.id)
          }
          subnet: {
            id: subnet0Ref
          }
        }
      }
    ]
  }
}

resource nicName_1 'Microsoft.Network/networkInterfaces@2017-10-01' = {
  name: '${nicName}1'
  location: location
  properties: {
    enableIPForwarding: true
    enableAcceleratedNetworking: ((imageVersion == '8.1.9') ? 'false' : 'true')
    ipConfigurations: [
      {
        name: 'ipconfig-untrust'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}

resource nicName_2 'Microsoft.Network/networkInterfaces@2017-10-01' = {
  name: '${nicName}2'
  location: location
  properties: {
    enableIPForwarding: true
    enableAcceleratedNetworking: ((imageVersion == '8.1.9') ? 'false' : 'true')
    ipConfigurations: [
      {
        name: 'ipconfig-trust'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet2Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}

resource availabilitySetName_resource 'Microsoft.Compute/availabilitySets@2018-06-01' = if (availabilitySetName != 'None') {
  name: availabilitySetName
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
  sku: {
    name: 'aligned'
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2018-06-01' = {
  name: vmName
  location: location
  plan: {
    name: imageSku
    product: imageOffer
    publisher: imagePublisher
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      customData: ((bootstrap == 'no') ? json('null') : base64(customData))
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_0.id
          properties: {
            primary: true
          }
        }
        {
          id: nicName_1.id
          properties: {
            primary: false
          }
        }
        {
          id: nicName_2.id
          properties: {
            primary: false
          }
        }
      ]
    }
    availabilitySet: ((availabilitySetName == 'None') ? json('null') : availabilitySet)
  }
  zones: ((zone == 'None') ? json('null') : zones)
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
    nsgName
  ]
}
