@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param cognitiveServiceName string = 'AzInsider-CognitiveService-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'S0'
])
param sku string = 'S0'

@description('Name for the container group')
param name string = 'azinsider-containergroup'

@description('Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries. Images from private registries require additional registry credentials.')
param image string = 'mcr.microsoft.com/azure-cognitive-services/textanalytics/language:1.1.013570001-amd64'

@description('Port to open on the container and the public IP address.')
param port int = 5000

@description('The number of CPU cores to allocate to the container.')
param cpuCores int = 4

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int = 8

@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'OnFailure'


//Create a cognitive services resource
resource cognitiveService 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: cognitiveServiceName
  location: location
  sku: {
    name: sku
  }
  kind: 'CognitiveServices'
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
  }
}

output cognitiveServiceEndpoint string = cognitiveService.properties.endpoint
output cognitiveServiceKey string = cognitiveService.listKeys().key1


//Create azure container instance
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: name
  location: location
  properties: {
    containers: [
      {
        name: name
        properties: {
          image: image
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          environmentVariables: [
            {
              name: 'ApiKey'
              //secureValue: 'Yes' 
              value: cognitiveService.listKeys().key1 //Either key for your cognitive services resource
            }
            {
              name: 'Billing'
              //secureValue: 'No'
              value: cognitiveService.properties.endpoint //The endpoint URI for your cognitive services resource
            }
            {
              name: 'Eula'
              //secureValue: 'No'
              value: 'accept' //As is
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: restartPolicy
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
    }
  }
}

output containerIPv4Address string = containerGroup.properties.ipAddress.ip
