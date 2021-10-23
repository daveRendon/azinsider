@description('Linux VM user account name')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine')
param authenticationType string = 'password'

@description('Password or SSH key for the Virtual Machine')
@secure()
param adminPasswordOrSSHKey string

@description('User name for WildFly Manager')
param wildflyUserName string

@minLength(12)
@description('Password for WildFly Manager')
@secure()
param wildflyPassword string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated')
param artifactsLocation string

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string 

@description('Location for all resources')
param location string = resourceGroup().location

@description('The size of the Virtual Machine')
param vmSize string = 'Standard_D2s_v3'

var singlequote = '\''
var imagePublisher = 'OpenLogic'
var imageOffer = 'CentOS'
var imageSKU = '8.0'
var nicName_var = 'centos-vm-nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'centosvm-subnet'
var subnetPrefix = '10.0.0.0/24'
var vmName_var = 'centos-vm'
var virtualNetworkName_var = 'centosvm-vnet'
var bootStorageAccountName_var = 'bootstrg${uniqueString(resourceGroup().id)}'
var storageAccountType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrSSHKey
      }
    ]
  }
}
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var scriptFolder = 'scripts'
var fileToBeDownloaded = 'JBoss-EAP_on_Azure.war'
var scriptArgs = '-a ${uri(artifactsLocation, '.')} -t "${artifactsLocationSasToken}" -p ${scriptFolder} -f ${fileToBeDownloaded}'


resource bootStorageAccountName 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: bootStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  tags: {
    QuickstartName: 'WildFly 18 on CentOS 8 (stand-alone VM)'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    QuickstartName: 'WildFly 18 on CentOS 8 (stand-alone VM)'
  }
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

resource nicName 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: nicName_var
  location: location
  tags: {
    QuickstartName: 'WildFly 18 on CentOS 8 (stand-alone VM)'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
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

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  tags: {
    QuickstartName: 'WildFly 18 on CentOS 8 (stand-alone VM)'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrSSHKey
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(bootStorageAccountName_var, '2021-02-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    bootStorageAccountName
  ]
}

resource vmName_wildfly_setup 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: vmName
  name: 'wildfly-setup'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/wildfly-setup.sh${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh wildfly-setup.sh ${scriptArgs} ${wildflyUserName} ${singlequote}${wildflyPassword}${singlequote}'
      }
  }
}

output vm_Private_IP_Address string = nicName.properties.ipConfigurations[0].properties.privateIPAddress
output appURL string = 'http://${nicName.properties.ipConfigurations[0].properties.privateIPAddress}:8080/JBoss-EAP_on_Azure/'
output adminConsole string = 'http://${nicName.properties.ipConfigurations[0].properties.privateIPAddress}:9990'
