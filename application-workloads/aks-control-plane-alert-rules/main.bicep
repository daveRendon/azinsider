param location string = 'global'

@description('AKS cluster name')
param aksClusterName string

@description('Resource group of the AKS cluster')
param aksResourceGroup string

@description('Email for alert notifications')
param notificationEmail string

@description('Name for the Action Group')
param actionGroupName string = 'AKSAlertsActionGroup'

@description('Short name (max 12 chars) for Action Group')
param actionGroupShortName string = 'aksAG'

// Reference existing AKS cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-07-01' existing = {
  name: aksClusterName
  scope: resourceGroup(aksResourceGroup)
}

// Create Action Group
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: [
      {
        name: 'AdminEmail'
        emailAddress: notificationEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// API Server Memory Usage Alert
resource apiServerMemoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'API-Server-Memory-High-Alert'
  location: location
  properties: {
    description: 'API Server memory usage exceeded 80%.'
    severity: 2
    enabled: true
    scopes: [
      aksCluster.id
    ]
    evaluationFrequency: 'PT1M' // every 1 minute
    windowSize: 'PT5M'          // 5 minutes window
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          metricName: 'apiserver_memory_usage_percentage'
          metricNamespace: 'Microsoft.ContainerService/managedClusters'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          name: 'API Server Memory Usage'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ETCD Database Usage Alert
resource etcdDatabaseAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'ETCD-Database-High-Usage-Alert'
  location: location
  properties: {
    description: 'ETCD database usage exceeded 75%.'
    severity: 2
    enabled: true
    scopes: [
      aksCluster.id
    ]
    evaluationFrequency: 'PT5M' // every 5 minutes
    windowSize: 'PT15M'         // 15 minutes window
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          metricName: 'etcd_database_usage_percentage'
          metricNamespace: 'Microsoft.ContainerService/managedClusters'
          operator: 'GreaterThan'
          threshold: 75
          timeAggregation: 'Average'
          name: 'ETCD Database Usage'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

output actionGroupId string = actionGroup.id
