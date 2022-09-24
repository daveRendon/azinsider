@description('Username for the Virtual Machine.')
param vmAdminUserName string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param vmAdminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

@description('Name for the Public IP used to access the Virtual Machine.')
param publicIpName string = 'myPublicIP'

@description('Allocation method for the Public IP used to access the Virtual Machine.')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('SKU for the Public IP used to access the VM.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@description('The Windows version for the VM.')
@allowed([
'2022-datacenter'
'2022-datacenter-azure-edition-core'
'win11-22h2-avd'
])
param OSVersion string = 'win11-22h2-avd'

@description('VM Publisher.')
@allowed([
'microsoftwindowsdesktop'
'MicrosoftWindowsServer'
])
param publisher string = 'microsoftwindowsdesktop'

@description('VM Offer.')
@allowed([
'WindowsServer'
'windows-11'
])
param vmOffer string = 'windows-11'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2s_v5'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string = 'az-vm'

@description('Version of Office to deploy')
@allowed([
  'Office2016'
  'Office2013'
])
param officeVersion string = 'Office2016'

@description('script to execute')
param setupOfficeScriptFileName string = 'office-proplus-deployment.ps1'

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = 'MyVNET'
var networkSecurityGroupName = 'default-NSG'




resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vn.name, subnetName)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: vmOffer
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}


resource SetupOffice 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: vm
  name: 'SetupOffice'
  location: location
  tags: {
    displayName: 'SetupOffice'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://gist.githubusercontent.com/daveRendon/1c8f52ae7e8d9453caecb157c6f5f549/raw/d10cc6143d4f3369cc3c78ba47a0a558935ebf75/office-proplus-deployment.ps1'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/DefaultConfiguration.xml'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Office2013Setup.exe'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Office2016Setup.exe'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Edit-OfficeConfigurationFile.ps1'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Generate-ODTConfigurationXML.ps1'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Install-OfficeClickToRun.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy bypass -File ${setupOfficeScriptFileName} -OfficeVersion ${officeVersion}'
    }
  }
}

output hostname string = pip.properties.dnsSettings.fqdn
