@description('The name of the automation rule that will be deployed')
param automationRuleName string

param location string = resourceGroup().location
param sentinelName string

@minValue(30)
@maxValue(730)
param retentionInDays int = 90

var workspaceName = '${location}-${sentinelName}-${uniqueString(resourceGroup().id)}'
var solutionName = 'SecurityInsights(${sentinelWorkspace.name})'

resource sentinelWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: solutionName
  location: location
  properties: {
    workspaceResourceId: sentinelWorkspace.id
  }
  plan: {
    name: solutionName
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
}

resource automationRuleGuid 'Microsoft.SecurityInsights/automationRules@2022-10-01-preview' = {
  scope: sentinelWorkspace
  name: automationRuleName
  properties: {
    displayName: automationRuleName
    order: 2
    triggeringLogic: {
      isEnabled: true
      expirationTimeUtc: null
      triggersOn: 'Incidents'
      triggersWhen: 'Created'
      conditions: [
        {
          conditionType: 'Property'
          conditionProperties: {
            propertyName: 'IncidentSeverity'
            operator: 'Equals'
            propertyValues: [
              'High'
            ]
          }
        }
        {
          conditionType: 'Property'
          conditionProperties: {
            propertyName: 'IncidentTactics'
            operator: 'Contains'
            propertyValues: [
              'InitialAccess'
              'Execution'
            ]
          }
        }
        {
          conditionType: 'Property'
          conditionProperties: {
            propertyName: 'IncidentTitle'
            operator: 'Contains'
            propertyValues: [
              'urgent'
            ]
          }
        }
      ]
    }
    actions: [
      {
        order: 2
        actionType: 'ModifyProperties'
        actionConfiguration: {
          status: 'Closed'
          classification: 'Undetermined'
          classificationReason: null
        }
      }
      {
        order: 3
        actionType: 'ModifyProperties'
        actionConfiguration: {
          labels: [
            {
              labelName: 'tag'
            }
          ]
        }
      }
    ]
  }
}
