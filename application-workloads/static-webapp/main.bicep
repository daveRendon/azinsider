param name string
param location string = resourceGroup().location
param sku string
param skucode string
param repositoryUrl string
param branch string

@secure()
param repositoryToken string
param appLocation string
param apiLocation string
param appArtifactLocation string
param resourceTags object
param appSettings object

resource name_resource 'Microsoft.Web/staticSites@2021-01-15' = {
  name: name
  location: location
  tags: resourceTags
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    repositoryToken: repositoryToken
    buildProperties: {
      appLocation: appLocation
      apiLocation: apiLocation
      appArtifactLocation: appArtifactLocation
    }
  }
  sku: {
    tier: sku
    name: skucode
  }
}

resource name_appsettings 'Microsoft.Web/staticSites/config@2021-01-15' = {
  parent: name_resource
  name: 'appsettings'
  properties: appSettings
}
