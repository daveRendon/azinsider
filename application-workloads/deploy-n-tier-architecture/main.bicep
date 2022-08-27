param username string = 'adminaccount'
param location string = resourceGroup().location
@secure()
param password string
param sqlServerName string = 'demo-dbserver-${uniqueString(resourceGroup().id)}'

var deploymentUrl = 'https://raw.githubusercontent.com/daveRendon/n-tier-architecture/master/Deployment/'
var sqlServerDatabaseName = 'demo-sqldb'
var vnetName_var = 'demo-vnet'
var vnetAddressPrefix = '10.1.0.0/16'
var webNSGName_var = 'demo-web-nsg'
var webNSGResourceId = webNSGName.id
var webVMName_var = 'demo-web-vm'
var webVMNicName_var = 'demo-web-vm-nic'
var webVMNicPIPName_var = 'demo-web-vm-nic-pip'
var webSubnetName = 'demo-web-subnet'
var webSubnetPrefix = '10.1.0.0/24'
var bizVMName_var = 'demo-biz-vm'
var bizVMNicName_var = 'demo-biz-vm-nic'
var bizNSGName_var = 'demo-biz-nsg'
var bizSubnetName = 'demo-biz-subnet'
var bizSubnetPrefix = '10.1.1.0/24'
var bizNSGResourceId = bizNSGName.id
var webVMNicResourceId = webVMNicName.id
var webVMNicPIPResourceId = webVMNicPIPName.id
var webSubnetResourceId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, webSubnetName)
var bizVMNicResourceId = bizVMNicName.id
var bizSubnetResourceId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, bizSubnetName)

resource sqlServerName_resource 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    tier: 'data'
  }
  
  properties: {
    administratorLogin: username
    administratorLoginPassword: password
    version: '12.0'
  }
  dependsOn: []
}

resource sqlServerName_sqlServerDatabaseName 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  parent: sqlServerName_resource
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  name: sqlServerDatabaseName
  location: location
  tags: {
    tier: 'data'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource sqlServerName_demo_vnet_biz_rule 'Microsoft.Sql/servers/virtualNetworkRules@2015-05-01-preview' = {
  parent: sqlServerName_resource
  name: 'demo-vnet-biz-rule'
  properties: {
    ignoreMissingVnetServiceEndpoint: false
    virtualNetworkSubnetId: bizSubnetResourceId
  }
  dependsOn: [
    vnetName
    sqlServerName_resource
  ]
}

resource webNSGName 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: webNSGName_var
  location: location
  tags: {
    tier: 'presentation'
  }
  properties: {
    securityRules: [
      {
        name: 'http'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: []
}

resource bizNSGName 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: bizNSGName_var
  location: location
  tags: {
    tier: 'application'
  }
  properties: {
    securityRules: [
      {
        name: 'http'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '10.1.0.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 400
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: []
}

resource vnetName 'Microsoft.Network/virtualNetworks@2018-08-01' = {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: webSubnetName
        properties: {
          addressPrefix: webSubnetPrefix
        }
      }
      {
        name: bizSubnetName
        properties: {
          addressPrefix: bizSubnetPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql'
              locations: [
                location
              ]
            }
          ]
        }
      }
    ]
  }
  dependsOn: []
}

resource webVMNicPIPName 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  name: webVMNicPIPName_var
  location: location
  tags: {
    tier: 'presentation'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
  dependsOn: []
}

resource webVMNicName 'Microsoft.Network/networkInterfaces@2018-08-01' = {
  name: webVMNicName_var
  location: location
  tags: {
    tier: 'presentation'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.1.0.4'
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: webVMNicPIPResourceId
          }
          subnet: {
            id: webSubnetResourceId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    primary: true
    networkSecurityGroup: {
      id: webNSGResourceId
    }
  }
  dependsOn: [
    vnetName
    webNSGName
  ]
}

resource bizVMNicName 'Microsoft.Network/networkInterfaces@2018-08-01' = {
  name: bizVMNicName_var
  location: location
  tags: {
    tier: 'application'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.1.1.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: bizSubnetResourceId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    primary: true
    networkSecurityGroup: {
      id: bizNSGResourceId
    }
  }
  dependsOn: [
    vnetName
    bizNSGName
  ]
}

resource webVMName 'Microsoft.Compute/virtualMachines@2018-06-01' = {
  name: webVMName_var
  location: location
  tags: {
    tier: 'presentation'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${webVMName_var}-disk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 30
      }
      dataDisks: []
    }
    osProfile: {
      computerName: webVMName_var
      adminUsername: username
      adminPassword: password
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: webVMNicResourceId
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource webVMName_apache_ext 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  parent: webVMName
  name: 'apache-ext'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: true
    }
    protectedSettings: {
      commandToExecute: 'sh setup-votingweb.sh'
      fileUris: [
        uri(deploymentUrl, 'setup-votingweb.sh')
        uri(deploymentUrl, 'votingweb.conf')
        uri(deploymentUrl, 'votingweb.service')
        uri(deploymentUrl, 'votingweb.zip')
      ]
    }
  }
}

resource bizVMName 'Microsoft.Compute/virtualMachines@2018-06-01' = {
  name: bizVMName_var
  location: location
  tags: {
    tier: 'application'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${bizVMName_var}-disk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 30
      }
      dataDisks: []
    }
    osProfile: {
      computerName: bizVMName_var
      adminUsername: username
      adminPassword: password
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: bizVMNicResourceId
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource bizVMName_apache_ext 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: bizVMName
  name: 'apache-ext'
  location: location
  tags: {
    displayName: 'customScript for Linux VM'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: true
      fileUris: [
        uri(deploymentUrl, 'setup-votingdata.sh')
        uri(deploymentUrl, 'votingdata.conf')
        uri(deploymentUrl, 'votingdata.service')
        uri(deploymentUrl, 'votingdata.zip')
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh setup-votingdata.sh ${sqlServerName} ${username} ${password}'
    }
  }
}

output webSiteUrl string = 'http://${webVMNicPIPName.properties.ipAddress}'
