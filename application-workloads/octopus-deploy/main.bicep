@description('Admin username for the Octopus Deploy Virtual Machine.')
param vmAdminUsername string = 'octoadmin'

@description('Admin password for the Octopus Deploy Virtual Machine.')
@secure()
param vmAdminPassword string

@description('Unique DNS Name used to access the Octopus Deploy server via HTTP or RDP.')
param networkDnsName string

@description('Unique DNS Name for the SQL DB Server that will hold the Octopus Deploy data.')
param sqlServerName string

@description('Admin username for the Octopus Deploy SQL DB Server.')
param sqlAdminUsername string = 'sqladmin'

@description('Admin password for the Octopus Deploy SQL DB Server.')
@secure()
param sqlAdminPassword string

@description('Admin password for the Octopus Deploy web application.')
param vmSize string = 'Standard_DS3_v2'

@description('Admin password for the Octopus Deploy web application.')
param vmName string

@description('Admin password for the Octopus Deploy web application.')
param location string = resourceGroup().location

var storageAccountName_var = '${uniqueString(resourceGroup().id)}storage'
var vmImagePublisher = 'MicrosoftWindowsServer'
var vmImageOffer = 'WindowsServer'
var vmWindowsOSVersion = '2022-datacenter-azure-edition'
var networkNicName_var = 'OctopusDeployNIC'
var networkAddressPrefix = '10.0.0.0/16'
var networkSubnetName = 'OctopusDeploySubnet'
var networkSubnetPrefix = '10.0.0.0/24'
var networkPublicIPAddressName_var = 'OctopusDeployPublicIP'
var networkPublicIPAddressType = 'Dynamic'
var networkVNetName_var = 'OctopusDeployVNET'
var networkSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', networkVNetName_var, networkSubnetName)
var sqlDbName = 'OctopusDeploy'
var sqlDbCollation = 'SQL_Latin1_General_CP1_CI_AS'
var sqlDbMaxSizeBytes = 268435456000

resource storageAccountName 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {}
}

resource networkPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: networkPublicIPAddressName_var
  location: location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    publicIPAllocationMethod: networkPublicIPAddressType
    dnsSettings: {
      domainNameLabel: networkDnsName
    }
  }
}

resource networkVNetName 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: networkVNetName_var
  location: location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkAddressPrefix
      ]
    }
    subnets: [
      {
        name: networkSubnetName
        properties: {
          addressPrefix: networkSubnetPrefix
        }
      }
    ]
  }
}

resource networkNicName 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: networkNicName_var
  location: location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: networkPublicIPAddressName.id
          }
          subnet: {
            id: networkSubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    networkVNetName
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmWindowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkNicName.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource vmName_OctopusDeployInstaller 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmName_resource
  name: 'OctopusDeployInstaller'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://gist.githubusercontent.com/daveRendon/882e6d2c829ef32b8c72e5d4e5d06df6/raw/d0849f405f55a290f8665891977dc9acb976af9f/Install-OctopusDeploy.ps1'
      ]
      commandToExecute: 'powershell.exe -File Install-OctopusDeploy.ps1'
    }
  }
  dependsOn: [
    sqlServerName_sqlDbName
  ]
}

resource sqlServerName_resource 'Microsoft.Sql/servers@2020-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    version: '12.0'
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
  }
}

resource sqlServerName_sqlDbName 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  parent: sqlServerName_resource
  name: sqlDbName
  location: location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    collation: sqlDbCollation
    maxSizeBytes: sqlDbMaxSizeBytes
  }
}

resource sqlServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2020-08-01-preview' = {
  parent: sqlServerName_resource
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output octopusServerName string = networkPublicIPAddressName.properties.dnsSettings.fqdn
output sqlServerName string = sqlServerName_resource.properties.fullyQualifiedDomainName
