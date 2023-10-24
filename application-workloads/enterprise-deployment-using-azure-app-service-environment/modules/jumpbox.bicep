@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where the jumpbox will be connected.')
param vnetName string

@description('The ip address prefix that jumpbox subnet will use.')
param jumpboxSubnetAddressPrefix string

@description('The admin user name.')
param adminUsername string = 'azureuser'

@description('The admin password.')
@secure()
param adminPassword string = 'Azuretest01!!'

var computerName = 'votingjb'
var jumpboxName = 'jumpboxVm'
var jumpboxSubnetName = 'jumpbox-subnet'
var jumpboxSubnetId = jumpboxSubnet.id
var jumpboxPublicIpName = 'jumpbox-pip'
var jumpboxNSGName = 'jumpbox-nsg'
var jumpboxNicName = 'jumpbox-nic'

resource jumpboxPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: jumpboxPublicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource jumpboxNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: jumpboxNSGName
  location: location
  tags: {
    displayName: jumpboxNSGName
  }
  properties: {
    securityRules: [
      {
        name: 'JUMPBOX-inbound-allow_RDP'
        properties: {
          description: 'Allow Inbound-JumpBoxRDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: jumpboxSubnetAddressPrefix
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource jumpboxSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${vnetName}/${jumpboxSubnetName}'
  properties: {
    addressPrefix: jumpboxSubnetAddressPrefix
    networkSecurityGroup: {
      id: jumpboxNSG.id
    }
  }
}

resource jumpboxNic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: jumpboxNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: jumpboxSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', jumpboxPublicIpName)
          }
        }
      }
    ]
  }
}

resource jumpbox 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: jumpboxName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-smalldisk'
        version: 'latest'
      }
      dataDisks: [
        {
          diskSizeGB: 512
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNic.id
        }
      ]
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
}

output jumpboxName string = jumpboxName
output jumpboxSubnetName string = jumpboxSubnetName
output jumpboxPublicIpAddress string = jumpboxPublicIp.properties.ipAddress
