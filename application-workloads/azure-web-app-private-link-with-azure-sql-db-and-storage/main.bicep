@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param _artifactsLocation string = 'REPLACE-WITH-YOUR-ARTIFACTS-LOCATION'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param _artifactsLocationSasToken string = 'REPLACE-WITH-YOUR-ARTIFACTS-LOCATION-SAS-TOKEN'

@description('deployment location')
param location string = resourceGroup().location

@description('unique web app name')
param webAppName string = 'web-app-${uniqueString(subscription().id, resourceGroup().id)}'

@description('Azure SQL DB administrator login name')
param sqlAdministratorLoginName string

@description('Azure SQL DB administrator password')
@secure()
param sqlAdministratorLoginPassword string

@description('JSON object describing virtual networks & subnets')
param vNets array

var suffix = substring(replace(guid(resourceGroup().id), '-', ''), 0, 6)
var appName = '${webAppName}-${suffix}'
var storagePrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var sqlPrivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var sqlDatabaseName = 'mydb01'
var storageContainerName = 'mycontainer'
var storageGroupType = 'blob'
var sqlGroupType = 'sqlServer'
var vnetNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/vnets.json${_artifactsLocationSasToken}')
var vnetPeeringNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/vnet_peering.json${_artifactsLocationSasToken}')
var appServicePlanNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/app_svc_plan.json${_artifactsLocationSasToken}')
var appNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/app.json${_artifactsLocationSasToken}')
var sqlNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/sqldb.json${_artifactsLocationSasToken}')
var privateLinkNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/private_link.json${_artifactsLocationSasToken}')
var storageNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/storage.json${_artifactsLocationSasToken}')
var privateDnsNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/private_dns.json${_artifactsLocationSasToken}')
var privateDnsRecordNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/dns_record.json${_artifactsLocationSasToken}')
var privateLinkIpConfigsNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/private_link_ipconfigs.json${_artifactsLocationSasToken}')
var privateLinkIpConfigsHelperNestedTemplateUri = uri(_artifactsLocation, 'nestedtemplates/private_link_ipconfigs_helper.json${_artifactsLocationSasToken}')

module linkedTemplate_vnet 'nestedtemplates/vnets.json' /*TODO: replace with correct path to [variables('vnetNestedTemplateUri')]*/ = [for (item, i) in vNets: {
  name: 'linkedTemplate-vnet-${i}'
  params: {
    suffix: suffix
    location: location
    vNets: item
  }
}]

module linkedTemplate_peerings 'nestedtemplates/vnet_peering.json' /*TODO: replace with correct path to [variables('vnetPeeringNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-peerings'
  params: {
    suffix: suffix
    location: location
    vNets: vNets
  }
  dependsOn: [
    linkedTemplate_vnet
  ]
}

module linkedTemplate_app_svc_plan 'nestedtemplates/app_svc_plan.json' /*TODO: replace with correct path to [variables('appServicePlanNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-app-svc-plan'
  params: {
    suffix: suffix
    location: location
    serverFarmSku: {
      Tier: 'Standard'
      Name: 'S1'
    }
  }
  dependsOn: [
    linkedTemplate_vnet
  ]
}

module linkedTemplate_app 'nestedtemplates/app.json' /*TODO: replace with correct path to [variables('appNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-app'
  params: {
    location: location
    hostingPlanName: linkedTemplate_app_svc_plan.outputs.serverFarmName
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-1')).outputs.subnetResourceIds.value[0].id
    appName: appName
    ipAddressRestriction: [
      '0.0.0.0/32'
    ]
  }
}

module linkedTemplate_sqldb 'nestedtemplates/sqldb.json' /*TODO: replace with correct path to [variables('sqlNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb'
  params: {
    suffix: suffix
    location: location
    sqlAdministratorLogin: sqlAdministratorLoginName
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    databaseName: sqlDatabaseName
  }
  dependsOn: [
    linkedTemplate_vnet
  ]
}

module linkedTemplate_sqldb_private_link 'nestedtemplates/private_link.json' /*TODO: replace with correct path to [variables('privateLinkNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.Sql/servers'
    resourceName: linkedTemplate_sqldb.outputs.sqlServerName
    groupType: sqlGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-0')).outputs.subnetResourceIds.value[0].id
  }
}

module linkedTemplate_storage 'nestedtemplates/storage.json' /*TODO: replace with correct path to [variables('storageNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage'
  params: {
    suffix: suffix
    location: location
    containerName: storageContainerName
    defaultNetworkAccessAction: 'Deny'
  }
  dependsOn: [
    linkedTemplate_vnet
  ]
}

module linkedTemplate_storage_private_link 'nestedtemplates/private_link.json' /*TODO: replace with correct path to [variables('privateLinkNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.Storage/storageAccounts'
    resourceName: linkedTemplate_storage.outputs.storageAccountName
    groupType: storageGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-0')).outputs.subnetResourceIds.value[0].id
  }
}

module linkedTemplate_storage_private_dns_spoke_link 'nestedtemplates/private_dns.json' /*TODO: replace with correct path to [variables('privateDnsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage-private-dns-spoke-link'
  params: {
    privateDnsZoneName: storagePrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-1')).outputs.virtualNetworkName.value
  }
  dependsOn: [
    linkedTemplate_storage_private_link
  ]
}

module linkedTemplate_storage_private_dns_hub_link 'nestedtemplates/private_dns.json' /*TODO: replace with correct path to [variables('privateDnsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage-private-dns-hub-link'
  params: {
    privateDnsZoneName: storagePrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-0')).outputs.virtualNetworkName.value
  }
  dependsOn: [
    linkedTemplate_storage_private_link
    linkedTemplate_storage_private_dns_spoke_link
  ]
}

module linkedTemplate_storage_private_link_ipconfigs 'nestedtemplates/private_link_ipconfigs.json' /*TODO: replace with correct path to [variables('privateLinkIpConfigsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage-private-link-ipconfigs'
  params: {
    privateDnsZoneName: storagePrivateDnsZoneName
    privateLinkNicResource: linkedTemplate_storage_private_link.outputs.privateLinkNicResource
    privateDnsRecordTemplateUri: privateDnsRecordNestedTemplateUri
    privateLinkNicIpConfigTemplateUri: privateLinkIpConfigsHelperNestedTemplateUri
  }
  dependsOn: [
    linkedTemplate_storage_private_dns_hub_link
  ]
}

module linkedTemplate_sqldb_private_dns_spoke_link 'nestedtemplates/private_dns.json' /*TODO: replace with correct path to [variables('privateDnsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb-private-dns-spoke-link'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-1')).outputs.virtualNetworkName.value
  }
  dependsOn: [
    linkedTemplate_sqldb_private_link
  ]
}

module linkedTemplate_sqldb_private_dns_hub_link 'nestedtemplates/private_dns.json' /*TODO: replace with correct path to [variables('privateDnsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb-private-dns-hub-link'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-0')).outputs.virtualNetworkName.value
  }
  dependsOn: [
    linkedTemplate_sqldb_private_link
    linkedTemplate_sqldb_private_dns_spoke_link
  ]
}

module linkedTemplate_sqldb_private_link_ipconfigs 'nestedtemplates/private_link_ipconfigs.json' /*TODO: replace with correct path to [variables('privateLinkIpConfigsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb-private-link-ipconfigs'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    privateLinkNicResource: linkedTemplate_sqldb_private_link.outputs.privateLinkNicResource
    privateDnsRecordTemplateUri: privateDnsRecordNestedTemplateUri
    privateLinkNicIpConfigTemplateUri: privateLinkIpConfigsHelperNestedTemplateUri
  }
  dependsOn: [
    linkedTemplate_sqldb_private_dns_hub_link
  ]
}
