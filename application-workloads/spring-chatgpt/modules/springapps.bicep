param location string
param asaInstanceName string
param asaManagedEnvironmentName string
param appName string
param relativePath string
param environmentVariables object = {}
param fileShareName string
param storageAccountName string
param storageMountName string

resource asaManagedEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: asaManagedEnvironmentName
  location: location
 
  properties: {
    workloadProfiles: [
	  {
		name: 'Consumption'
		workloadProfileType: 'Consumption'
	  }
	]
  }

  resource persistentStorage 'storages' = {
    name: 'vectorstore'
    properties: {
      azureFile: {
		accessMode: 'ReadOnly'
		accountKey: storage.listKeys().keys[0].value
		accountName: storageAccountName
		shareName: fileShareName
	  }
    }
  }
}


resource asaInstance 'Microsoft.AppPlatform/Spring@2023-03-01-preview' = {
  name: asaInstanceName
  location: location
  sku: {
    name: 'S0'
	tier: 'StandardGen2'
  }
  properties: {
	managedEnvironmentId: asaManagedEnvironment.id
  }
}

resource asaApp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: appName
  location: location
  parent: asaInstance
  properties: {
    public: true
    activeDeploymentName: 'default'
    customPersistentDisks: [
      {
		customPersistentDiskProperties: {
		  mountPath: '/opt/spring-chatgpt-sample'
		  type: 'AzureFileVolume'
		  shareName: fileShareName
		}
		storageId: storageMountName
      }
    ]
  }
}

resource asaDeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2023-03-01-preview' = {
  name: 'default'
  parent: asaApp
  properties: {
    source: {
      type: 'Jar'
      relativePath: relativePath
      runtimeVersion: 'Java_17'
      jvmOptions: '-Xms1024m -Xmx2048m'
    }
    deploymentSettings: {
      resourceRequests: {
        cpu: '1'
        memory: '2Gi'
      }
      scale: {
        maxReplicas: 2
        minReplicas: 2
      }
      environmentVariables: environmentVariables
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

output name string = asaApp.name
output uri string = 'https://${asaApp.properties.url}'
