@description('Name of the Storage Account')
param newStorageAccountName string

@description('Username for the Administrator of the VM')
param adminUsername string

@description('Image Publisher')
param imagePublisher string = 'Canonical'

@description('Image Offer')
param imageOffer string = 'UbuntuServer'

@description('Image SKU')
param imageSKU string = '18.04-LTS'

@description('DNS Name for the Public IP. Must be lowercase.')
param vmDnsName string

@description('Admin username for SQL Database')
param administratorLogin string

@description('Admin password for SQL Database')
@secure()
param administratorLoginPassword string

@description('SQL Collation')
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Name of your SQL Database')
param databaseName string

@description('Max DB size in bytes')
param maxSizeBytes int = 268435456000

@description('Requested Service Objective ID')
param requestedServiceObjectiveId string = 'f1173c43-91bd-4aaa-973c-54e79e15235b'

@description('Unique name of your SQL Server')
param serverName string

@description('Start IP for your firewall rule, for example 0.0.0.0')
param firewallStartIP string = '0.0.0.0'

@description('End IP for your firewall rule, for example 255.255.255.255')
param firewallEndIP string = '0.0.0.0'

@description('SQL Version')
param version string = '12.0'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Default VM Size')
param vmSize string = 'Standard_B1s'

var nicName_var = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet-1'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmName_var = vmDnsName
var virtualNetworkName_var = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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

resource serverName_resource 'Microsoft.Sql/servers@2020-11-01-preview' = {
  location: location
  name: serverName
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: version
  }
}

resource serverName_databaseName 'Microsoft.Sql/servers/databases@2020-11-01-preview' = {
  parent: serverName_resource
  location: location
  name: databaseName
  properties: {
    collation: collation
    maxSizeBytes: maxSizeBytes
    recoveryServicesRecoveryPointId: requestedServiceObjectiveId
  }
}

resource serverName_FirewallRule1 'Microsoft.Sql/servers/firewallrules@2020-11-01-preview' = {
  parent: serverName_resource
  name: 'FirewallRule1'
  properties: {
    endIpAddress: firewallEndIP
    startIpAddress: firewallStartIP
  }
}

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: newStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmDnsName
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  name: virtualNetworkName_var
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
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-07-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
  ]
}

resource vmName_django 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmName
  name: 'django'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://gist.githubusercontent.com/daveRendon/bf68e2b419a5907eb639e6265be70cda/raw/818c370103e09ea61c5cd4d573ee8e9d77d6fc09/install_django.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh install_django.sh ${vmDnsName} ${serverName} ${administratorLogin} ${administratorLoginPassword} ${databaseName}'
    }
  }
}
