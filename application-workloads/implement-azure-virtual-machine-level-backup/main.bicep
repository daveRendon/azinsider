param location string = resourceGroup().location

@description('Resource group where the virtual machines are located. This can be different than resource group of the vault. ')
param existingVirtualMachinesResourceGroup string = 'azinsider_demo'

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('VM name prefix')
param vmNamePrefix string = 'az104-10-vm'

@description('Public IP address name prefix')
param pipNamePrefix string = 'az104-10-pip'

@description('Nic name prefix')
param nicNamePrefix string = 'az104-10-nic'

@description('Image Publisher')
param imagePublisher string = 'MicrosoftWindowsServer'

@description('Image Offer')
param imageOffer string = 'WindowsServer'

@description('Image SKU')
@allowed([
  '2019-Datacenter'
  '2019-Datacenter-Server-Core'
  '2019-Datacenter-Server-Core-smalldisk'
])
param imageSKU string = '2019-Datacenter'

@description('VM size')
param vmSize string = 'Standard_D2s_v3'

@description('Array of Azure virtual machines.')
param existingVirtualMachines array = [
  'az104-10-vm0'
  'az104-10-vm1'
]

@description('Virtual network name')
param virtualNetworkName string = 'az104-10-vnet'

@description('Virtual network address prefix')
param addressPrefix string = '10.0.0.0/24'

@description('Resource group of the VNet')
param virtualNetworkResourceGroup string = 'az104-10-rg0'

@description('VNet first subnet name')
param subnet0Name string = 'subnet0'

@description('VNet first subnet prefix')
param subnet0Prefix string = '10.0.0.0/26'

@description('Network security group name')
param nsgName string = 'az104-10-nsg01'

var vnetID = resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet0Name)
var numberOfInstances = 2
var vaultName = 'az104-10-rsv1'
var backupFabric = 'Azure'

var scheduleRunTimes = [
  '2022-01-26T05:30:00Z'
]
var backupPolicyName = 'az104-DefaultPolicy'
@description('Conditional parameter for New or Existing Backup Policy')
param isNewPolicy bool = true
var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'


resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = [for i in range(0, numberOfInstances): {
  name: '${nicNamePrefix}${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIpAddresses', '${pipNamePrefix}${i}')
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
    pip
  ]
}]

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
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
        name: subnet0Name
        properties: {
          addressPrefix: subnet0Prefix
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = [for i in range(0, numberOfInstances): {
  name: '${pipNamePrefix}${i}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, numberOfInstances): {
  name: '${vmNamePrefix}${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmNamePrefix}${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNamePrefix}${i}')
        }
      ]
    }
  }
  dependsOn: [
    nic
  ]
}]

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfInstances): {
  name: '${vmNamePrefix}${i}/customScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe Set-ExecutionPolicy Bypass -Scope Process -Force && powershell.exe Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(\'https://chocolatey.org/install.ps1\')) && powershell.exe c:\\programdata\\chocolatey\\choco.exe install microsoft-edge -y'
    }
  }
  dependsOn: [
    vm[i]
  ]
}]


resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-01-01' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
  dependsOn: [
    customScriptExtension
  ]
}



resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-03-01' = if (isNewPolicy) {
  parent: recoveryServicesVault
  name: backupPolicyName
  location: location
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: scheduleRunTimes
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      dailySchedule: {
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 104
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
          'Tuesday'
          'Thursday'
        ]
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 104
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 60
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: [
          'January'
          'March'
          'August'
        ]
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 10
          durationType: 'Years'
        }
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
    }
    timeZone: 'UTC'
  }

}




resource protectedItems 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2022-01-01' = [for item in existingVirtualMachines: {
  name: '${vaultName}/${backupFabric}/${v2VmContainer}${existingVirtualMachinesResourceGroup};${item}/${v2Vm}${existingVirtualMachinesResourceGroup};${item}'
  location: location
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: backupPolicy.id
    sourceResourceId: resourceId(subscription().subscriptionId, existingVirtualMachinesResourceGroup, 'Microsoft.Compute/virtualMachines', '${item}')
  }
  dependsOn: [
    recoveryServicesVault
  ]
}]
