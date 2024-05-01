targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string = 'azinsider'

@minLength(1)
@description('Primary location for all resources')
param location string = 'EastUS'

@description('Relative Path of ASA Jar')
param relativePath string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var storageAccountName = '${abbrs.storageStorageAccounts}${resourceToken}'
var fileShareName = 'vectorstore'
var storageMountName = 'vectorstore'
var cognitiveAccountName = '${abbrs.cognitiveServicesAccounts}${resourceToken}'
var asaInstanceName = '${abbrs.springApps}${resourceToken}'
var asaManagedEnvironmentName = '${abbrs.appContainerAppsManagedEnvironment}${resourceToken}'
var appName = 'spring-chatgpt'


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}-${resourceToken}'
  location: location
}

module storage 'modules/storage.bicep' = {
  name: '${deployment().name}--storage'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    storageAccountName: storageAccountName
	fileShareName: fileShareName
  }
}

module cognitive 'modules/cognitive.bicep' = {
  name: '${deployment().name}--cog'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    accountName: cognitiveAccountName
    deployments: [
	  {
		name: 'gpt-4-32k'
		model: {
		  format: 'OpenAI'
		  name: 'gpt-4-32k'
		  version: '0613'
		}
		capacity: 30
	  }
	  {
		name: 'text-embedding-ada-002'
		model: {
		  format: 'OpenAI'
		  name: 'text-embedding-ada-002'
		  version: '2'
		}
		capacity: 30
	  }
	]
  }
}

module springApps 'modules/springapps.bicep' = {
  name: '${deployment().name}--asa'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    appName: appName
    asaInstanceName: asaInstanceName
	asaManagedEnvironmentName: asaManagedEnvironmentName
    relativePath: relativePath
    storageAccountName: storageAccountName
	fileShareName: fileShareName
	storageMountName: storageMountName
	environmentVariables: {
	  AZURE_OPENAI_ENDPOINT: cognitive.outputs.endpoint
	  AZURE_OPENAI_APIKEY: cognitive.outputs.key
	  AZURE_OPENAI_CHATDEPLOYMENTID: 'gpt-35-turbo'
	  AZURE_OPENAI_EMBEDDINGDEPLOYMENTID: 'text-embedding-ada-002'
	  VECTORSTORE_FILE: '/opt/spring-chatgpt-sample/doc_store.json'
	}
  }
  dependsOn: [
    storage
  ]
}

output STORAGE_ACCOUNT_NAME string = storageAccountName
output STORAGE_ACCOUNT_KEY string = storage.outputs.storageAccountKey
output AZURE_RESOURCE_GROUP string = rg.name
