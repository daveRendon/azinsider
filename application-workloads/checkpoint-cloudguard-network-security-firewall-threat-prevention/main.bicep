@description('Deployment location')
param location string = resourceGroup().location

@description('Version of Check Point CloudGuard')
@allowed([
  'R80.30 - Bring Your Own License'
  'R80.30 - Pay As You Go (MGMT25)'
  'R80.40 - Bring Your Own License'
  'R80.40 - Pay As You Go (MGMT25)'
  'R81 - Bring Your Own License'
  'R81 - Pay As You Go (MGMT25)'
  'R81.10 - Bring Your Own License'
  'R81.10 - Pay As You Go (MGMT25)'
])
param cloudGuardVersion string = 'R81.10 - Bring Your Own License'

@description('Default Admin username')
param adminUsername string = 'azureuser'

@description('Default Admin password')
@secure()
param adminPassword string

@description('Authentication type')
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = 'password'

@description('Administrator SSH public key')
param sshPublicKey string = ''

@description('Name of the Check Point Security Gateway')
param vmName string

@description('Size of the VM')
param vmSize string = 'Standard_D3_v2'

@description('The name of the virtual network')
param virtualNetworkName string = 'vnet'

@description('The address prefix of the virtual network')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('The name of the 1st subnet')
param Subnet1Name string = 'Frontend'

@description('The address prefix of the 1st subnet')
param subnet1Prefix string = '10.0.1.0/24'

@description('The first available address on the 1st subnet')
param Subnet1StartAddress string = '10.0.1.10'

@metadata({
  Description: 'Indicates whether the virtual network is new or existing'
})
@allowed([
  'new'
  'existing'
])
param vnetNewOrExisting string = 'new'

@description('Resource Group of the existing virtual network')
param virtualNetworkExistingRGName string = resourceGroup().name

@description('Allowed GUI clients')
param managementGUIClientNetwork string = '0.0.0.0/0'

@description('Installation Type')
@allowed([
  'management'
  'custom'
])
param installationType string = 'management'

@metadata({
  Description: 'The default shell for the admin user'
})
@allowed([
  '/etc/cli.sh'
  '/bin/bash'
  '/bin/csh'
  '/bin/tcsh'
])
param adminShell string = '/etc/cli.sh'

@description('Bootstrap script')
param bootstrapScript string = ''

@description('Accept Management API calls (NOTE: Works only in version R81.10 and above)')
@allowed([
  'management_only'
  'gui_clients'
  'all'
])
param enableApi string = 'management_only'

@description('Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point')
@allowed([
  'true'
  'false'
])
param allowDownloadFromUploadToCheckPoint string = 'true'

@description('Amount of additional disk space (in GB)')
@minValue(0)
@maxValue(3995)
param additionalDiskSizeGB int = 0

@description('The type of the OS disk. Premium is applicable only to DS machine sizes')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param diskType string = 'Standard_LRS'

@description('Configure managed service identity for the VM')
param msi bool = false

@description('The URI of the blob containing the development image')
param sourceImageVhdUri string = 'noCustomUri'

@description('Use the following URI when deploying a custom template: https://raw.githubusercontent.com/CheckPointSW/CloudGuardIaaS/master/azure/templates/')
param artifactsLocation string = 'https://raw.githubusercontent.com/CheckPointSW/CloudGuardIaaS/master/azure/templates/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var templateName = 'management'
var templateVersion = '20220130'
var location_var = location
var offers = {
  'R80.30 - Bring Your Own License': 'BYOL'
  'R80.30 - Pay As You Go (MGMT25)': 'MGMT25'
  'R80.40 - Bring Your Own License': 'BYOL'
  'R80.40 - Pay As You Go (MGMT25)': 'MGMT25'
  'R81 - Bring Your Own License': 'BYOL'
  'R81 - Pay As You Go (MGMT25)': 'MGMT25'
  'R81.10 - Bring Your Own License': 'BYOL'
  'R81.10 - Pay As You Go (MGMT25)': 'MGMT25'
}
var offer = offers[cloudGuardVersion]
var osVersions = {
  'R80.30 - Bring Your Own License': 'R8030'
  'R80.30 - Pay As You Go (MGMT25)': 'R8030'
  'R80.40 - Bring Your Own License': 'R8040'
  'R80.40 - Pay As You Go (MGMT25)': 'R8040'
  'R81 - Bring Your Own License': 'R81'
  'R81 - Pay As You Go (MGMT25)': 'R81'
  'R81.10 - Bring Your Own License': 'R8110'
  'R81.10 - Pay As You Go (MGMT25)': 'R8110'
}
var osVersion = osVersions[cloudGuardVersion]
var isBlink = bool('false')
var storageAccountName_var = 'bootdiag${uniqueString(resourceGroup().id, deployment().name)}'
var storageAccountType = 'Standard_LRS'
var diskSize100GB = 100
var diskSizeGB = (additionalDiskSizeGB + diskSize100GB)
var customData = '#!/usr/bin/python3 /etc/cloud_config.py\n\ninstallationType="${installationType}"\nallowUploadDownload="${allowUploadDownload}"\nosVersion="${osVersion}"\ntemplateName="${templateName}"\nisBlink="${isBlink}"\ntemplateVersion="${templateVersion}"\nbootstrapScript64="${bootstrapScript64}"\nlocation="${location_var}"\nmanagementGUIClientNetwork="${managementGUIClientNetwork_var}"\nenableApi="${enableApi}"\nadminShell="${adminShell}"\n'
var imageOffer = 'check-point-cg-${toLower(osVersion)}'
var imagePublisher = 'checkpoint'
var imageReferenceBYOL = {
  offer: imageOffer
  publisher: imagePublisher
  sku: 'mgmt-byol'
  version: 'latest'
}
var imageReferenceMGMT25 = {
  offer: imageOffer
  publisher: imagePublisher
  sku: 'mgmt-25'
  version: 'latest'
}
var imageReferenceMarketplace = ((offer == 'BYOL') ? imageReferenceBYOL : imageReferenceMGMT25)
var customImage_var = 'customImage'
var imageReferenceCustomUri = {
  id: customImage.id
}
var imageReference = ((sourceImageVhdUri == 'noCustomUri') ? imageReferenceMarketplace : imageReferenceCustomUri)
var nic1Name_var = '${vmName}-eth0'
var linuxConfigurationpassword = {
  disablePasswordAuthentication: 'false'
}
var linuxConfigurationsshPublicKey = {
  disablePasswordAuthentication: 'true'
  ssh: {
    publicKeys: [
      {
        keyData: sshPublicKey
        path: '/home/notused/.ssh/authorized_keys'
      }
    ]
  }
}
var linuxConfiguration = ((authenticationType == 'password') ? linuxConfigurationpassword : linuxConfigurationsshPublicKey)
var planBYOL = {
  name: 'mgmt-byol'
  product: imageOffer
  publisher: imagePublisher
}
var planMGMT25 = {
  name: 'mgmt-25'
  product: imageOffer
  publisher: imagePublisher
}
var plan = ((offer == 'BYOL') ? planBYOL : planMGMT25)
var identity = (msi ? json('{"type": "SystemAssigned"}') : json('null'))
var publicIPAddressName_var = '${vmName}-pip'
var publicIPAddressId = publicIPAddressName.id
var networkSecurityGroupName = '${vmName}-nsg'
var bootstrapScript64 = base64(bootstrapScript)
var allowUploadDownload = allowDownloadFromUploadToCheckPoint
var managementGUIClientNetwork_var = managementGUIClientNetwork
var deployNewVnet = (vnetNewOrExisting == 'new')
var vnetRGName = (deployNewVnet ? resourceGroup().name : virtualNetworkExistingRGName)


resource storageAccountName 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName_var
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
  location: location_var
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

// This will build a Virtual Network.
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: Subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  location: location
  name: publicIPAddressName_var
  properties: {
    idleTimeoutInMinutes: 30
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${toLower(vmName)}-${uniqueString(resourceGroup().id, deployment().name)}'
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  location: location
  name: networkSecurityGroupName
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          description: 'Allow inbound SSH connection'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: managementGUIClientNetwork_var
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'GAiA-portal'
        properties: {
          description: 'Allow inbound HTTPS access to the GAiA portal'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: managementGUIClientNetwork_var
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'SmartConsole-1'
        properties: {
          description: 'Allow inbound access using the SmartConsole GUI client'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '18190'
          sourceAddressPrefix: managementGUIClientNetwork_var
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'SmartConsole-2'
        properties: {
          description: 'Allow inbound access using the SmartConsole GUI client'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '19009'
          sourceAddressPrefix: managementGUIClientNetwork_var
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'Logs'
        properties: {
          description: 'Allow inbound logging connections from managed gateways'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '257'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
        }
      }
      {
        name: 'ICA-pull'
        properties: {
          description: 'Allow security gateways to pull a SIC certificate'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '18210'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 150
          direction: 'Inbound'
        }
      }
      {
        name: 'CRL-fetch'
        properties: {
          description: 'Allow security gateways to fetch CRLs'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '18264'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 160
          direction: 'Inbound'
        }
      }
      {
        name: 'Policy-fetch'
        properties: {
          description: 'Allow security gateways to fetch policy'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '18191'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 170
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nic1Name 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  location: location_var
  name: nic1Name_var
  properties: {
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: Subnet1StartAddress
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: publicIPAddressId
          }
          subnet: {
            id: resourceId(vnetRGName, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, Subnet1Name)
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}

resource customImage 'Microsoft.Compute/images@2020-06-01' = if (sourceImageVhdUri != 'noCustomUri') {
  name: customImage_var
  location: location_var
  properties: {
    storageProfile: {
      osDisk: {
        osType: 'Linux'
        osState: 'Generalized'
        blobUri: sourceImageVhdUri
        storageAccountType: 'Standard_LRS'
      }
    }
    hyperVGeneration: 'V1'
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  location: location_var
  name: vmName
  plan: ((sourceImageVhdUri == 'noCustomUri') ? plan : json('null'))
  identity: identity
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName.id, '2021-06-01').primaryEndpoints.blob
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1Name.id
          properties: {
            primary: true
          }
        }
      ]
    }
    osProfile: {
      adminPassword: adminPassword
      adminUsername: adminUsername
      computerName: toLower(vmName)
      customData: base64(customData)
      linuxConfiguration: linuxConfiguration
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: diskSizeGB
        name: vmName
        managedDisk: {
          storageAccountType: diskType
        }
      }
    }
  }
}

output IPAddress string = reference(publicIPAddressId).IpAddress
output FQDN string = reference(publicIPAddressId).dnsSettings.fqdn
