@description('The name for the logic app.')
param logicAppName string

@description('The SendGrid API key from the SendGrid service.')
@secure()
param sendgridApiKey string

@description('The name for the SendGrid connection.')
param sendgridName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource sendgrid 'Microsoft.Web/connections@2018-07-01-preview' = {
  location: location
  name: sendgridName
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sendgrid')
    }
    displayName: 'sengrid'
    parameterValues: {
      apiKey: sendgridApiKey
    }
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'request'
          kind: 'http'
          inputs: {
            schema: {
              '$schema': 'http://json-schema.org/draft-04/schema#'
              properties: {
                emailbody: {
                  type: 'string'
                }
                from: {
                  type: 'string'
                }
                subject: {
                  type: 'string'
                }
                to: {
                  type: 'string'
                }
              }
              required: [
                'from'
                'to'
                'subject'
                'emailbody'
              ]
              type: 'object'
            }
          }
        }
      }
      actions: {
        Send_email: {
          type: 'ApiConnection'
          inputs: {
            body: {
              body: '@{triggerBody()[\'emailbody\']}'
              from: '@{triggerBody()[\'from\']}'
              ishtml: false
              subject: '@{triggerBody()[\'subject\']}'
              to: '@{triggerBody()[\'to\']}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sendgrid\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/api/mail.send.json'
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          sendgrid: {
            id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/sendgrid'
            connectionId: sendgrid.id
          }
        }
      }
    }
  }
}
