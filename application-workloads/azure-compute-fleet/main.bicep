param addressPrefixes array
param subnets array
param virtualNetworkName string
param networkSecurityGroupName string
param location string
param securityRules array
param name string
param licenseType string
param zones array
param sizes array
param userName string

@secure()
param password string
param regularTargetCapacity string
param regularMinCapacity string
param regularAllocationStrategy string
param networkInterfaceConfigurationName string

var computerNamePrefix = toLower(substring(concat(name, uniqueString(resourceGroup().id)), 0, 9))
var networkApiVersion = '2020-11-01'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: securityRules
  }
}

resource name_resource 'Microsoft.AzureFleet/fleets@2024-05-01-preview' = {
  name: name
  location: location
  properties: {
    vmSizesProfile: sizes
    computeProfile: {
      computeApiVersion: '2023-09-01'
      baseVirtualMachineProfile: {
        storageProfile: {
          imageReference: {
            publisher: 'MicrosoftWindowsServer'
            offer: 'WindowsServer'
            sku: '2025-datacenter-g2'
            version: 'latest'
          }
          osDisk: {
            createOption: 'fromImage'
            caching: 'ReadWrite'
            osType: 'Windows'
            managedDisk: {
              storageAccountType: 'Premium_LRS'
            }
          }
        }
        licenseType: licenseType
        osProfile: {
          adminUsername: userName
          computerNamePrefix: computerNamePrefix
          windowsConfiguration: {
            provisionVMAgent: true
            enableAutomaticUpdates: true
          }
          adminPassword: password
        }
        networkProfile: {
          networkApiVersion: networkApiVersion
          networkInterfaceConfigurations: [
            {
              name: networkInterfaceConfigurationName
              properties: {
                primary: true
                enableAcceleratedNetworking: false
                networkSecurityGroup: {
                  id: networkSecurityGroup.id
                }
                ipConfigurations: [
                  {
                    name: '${take(networkInterfaceConfigurationName,(80-length('-ipConfig')))}-ipConfig'
                    properties: {
                      primary: true
                      subnet: {
                        id: '/subscriptions/your-subscription-id/resourceGroups/azinsider_demo/providers/Microsoft.Network/virtualNetworks/vnet-eastus-1/subnets/snet-eastus-1'
                      }
                      publicIPAddressConfiguration: {
                        name: '${networkInterfaceConfigurationName}-publicip'
                        properties: {
                          idleTimeoutInMinutes: 15
                        }
                      }
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    }
    regularPriorityProfile: {
      capacity: regularTargetCapacity
      minCapacity: regularMinCapacity
      allocationStrategy: regularAllocationStrategy
    }
  }
  zones: zones
  dependsOn: [
    virtualNetwork
  ]
}
