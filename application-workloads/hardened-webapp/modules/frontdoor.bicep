param frontDoorName string
param customBackendFqdn string

resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: frontDoorName
  location:'global'
  properties: {
    friendlyName: frontDoorName
    frontendEndpoints: [
      {
        name: '${frontDoorName}-azurefd-net'
        properties: {
          hostName: '${frontDoorName}.azurefd.net'
        }
      }
    ]
    backendPools: [
      {
        name: 'firewalled-webapp'
        properties: {
          backends: [
            {
              address: customBackendFqdn
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 50
              backendHostHeader: customBackendFqdn
              enabledState: 'Enabled'
            }
          ]
          healthProbeSettings: {
            id: concat(resourceId('Microsoft.Network/frontDoors', frontDoorName), '/healthProbeSettings/healthProbeSettings')
          }
          loadBalancingSettings: {
            id: concat(resourceId('Microsoft.Network/frontDoors', frontDoorName), '/loadBalancingSettings/loadBalancingSettings')
          }
        }
      }
    ]
    backendPoolsSettings: {
      enforceCertificateNameCheck: 'Enabled'
    }
    routingRules: [
      {
        name: 'root-https'
        properties: {
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: concat(resourceId('Microsoft.Network/frontDoors', frontDoorName), '/backendPools/firewalled-webapp')
            }
          }
          frontendEndpoints: [
            {
              id: concat(resourceId('Microsoft.Network/frontDoors', frontDoorName), '/frontendEndpoints/${frontDoorName}-azurefd-net')
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          enabledState: 'Enabled'
        }
      }
    ]
    healthProbeSettings: [
      {
        name: 'healthProbeSettings'
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 30
          enabledState: 'Enabled'
          healthProbeMethod: 'HEAD'
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: 'loadBalancingSettings'
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
          additionalLatencyMilliseconds: 0
        }
      }
    ]
  }
}
