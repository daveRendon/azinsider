targetScope = 'subscription'

param rgName string = 'azinsider_demo'
param rgLocation string = 'eastus'

@description('Specifiy whether you want to enable Standard tier for Virtual Machine resource type')
@allowed([
  'Standard'
  'Free'
])
param virtualMachineTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for Azure App Service resource type')
@allowed([
  'Standard'
  'Free'
])
param appServiceTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for PaaS SQL Service resource type')
@allowed([
  'Standard'
  'Free'
])
param paasSQLServiceTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for SQL Server on VM resource type')
@allowed([
  'Standard'
  'Free'
])
param sqlServerOnVmTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for Storage Account resource type')
@allowed([
  'Standard'
  'Free'
])
param storageAccountTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for Kubernetes service resource type')
@allowed([
  'Standard'
  'Free'
])
param kubernetesServiceTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for Container Registry resource type')
@allowed([
  'Standard'
  'Free'
])
param containerRegistryTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for Key Vault resource type')
@allowed([
  'Standard'
  'Free'
])
param keyvaultTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for Resource Manager resource type')
@allowed([
  'Standard'
  'Free'
])
param ArmTier string = 'Standard'

@description('Specify whether you want to enable Standard tier for DNS resource type')
@allowed([
  'Standard'
  'Free'
])
param DnsTier string = 'Standard'

resource VirtualMachines 'Microsoft.Security/pricings@2022-03-01' = {
  name: 'VirtualMachines'
  properties: {
    pricingTier: virtualMachineTier
  }
}

resource AppServices 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'AppServices'
  properties: {
    pricingTier: appServiceTier
  }
}

resource SqlServers 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'SqlServers'
  properties: {
    pricingTier: paasSQLServiceTier
  }
}

resource SqlServerVirtualMachines 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'SqlServerVirtualMachines'
  properties: {
    pricingTier: sqlServerOnVmTier
  }

}

resource StorageAccounts 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'StorageAccounts'
  properties: {
    pricingTier: storageAccountTier
  }
}

resource KubernetesService 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'KubernetesService'
  properties: {
    pricingTier: kubernetesServiceTier
  }
}

resource ContainerRegistry 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'ContainerRegistry'
  properties: {
    pricingTier: containerRegistryTier
  }
}

resource KeyVaults 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'KeyVaults'
  properties: {
    pricingTier: keyvaultTier
  }

}

resource Arm 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'Arm'
  properties: {
    pricingTier: ArmTier
  }
}

resource Dns 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'Dns'
  properties: {
    pricingTier: DnsTier
  }
}
