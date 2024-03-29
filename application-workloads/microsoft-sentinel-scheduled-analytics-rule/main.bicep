@description('Name for this scheduled alert rule. Must be unique for the workspace')
param ruleName string

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



resource ruleGuid 'Microsoft.SecurityInsights/alertRules@2021-03-01-preview' = {
  scope: sentinelWorkspace
  name: ruleName
  kind: 'Scheduled'
  properties: {
    displayName: 'Known IRIDIUM IP'
    description: 'IRIDIUM command and control IP. Identifies a match across various data feeds for IP IOCs related to the IRIDIUM activity group.'
    severity: 'High'
    enabled: true
    query: 'let IPList = dynamic(["154.223.45.38","185.141.207.140","185.234.73.19","216.245.210.106","51.91.48.210","46.255.230.229"]);\n(union isfuzzy=true\n(CommonSecurityLog\n| where isnotempty(SourceIP) or isnotempty(DestinationIP)\n| where SourceIP in (IPList) or DestinationIP in (IPList) or Message has_any (IPList)\n| extend IPMatch = case(SourceIP in (IPList), "SourceIP", DestinationIP in (IPList), "DestinationIP", "Message") \n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated) by SourceIP, DestinationIP, DeviceProduct, DeviceAction, Message, Protocol, SourcePort, DestinationPort, DeviceAddress, DeviceName, IPMatch\n| extend timestamp = StartTimeUtc, IPCustomEntity = case(IPMatch == "SourceIP", SourceIP, IPMatch == "DestinationIP", DestinationIP, "IP in Message Field") \n),\n(OfficeActivity\n|extend SourceIPAddress = ClientIP, Account = UserId\n| where  SourceIPAddress in (IPList)\n| extend timestamp = TimeGenerated , IPCustomEntity = SourceIPAddress , AccountCustomEntity = Account\n),\n(DnsEvents \n| extend DestinationIPAddress = IPAddresses,  Host = Computer\n| where  DestinationIPAddress has_any (IPList) \n| extend timestamp = TimeGenerated, IPCustomEntity = DestinationIPAddress, HostCustomEntity = Host\n),\n(imDns \n| extend DestinationIPAddress = DnsResponseName,  Host = Dvc\n| where  DestinationIPAddress has_any (IPList) \n| extend timestamp = TimeGenerated, IPCustomEntity = SrcIpAddr, HostCustomEntity = Host\n),\n(VMConnection \n| where isnotempty(SourceIp) or isnotempty(DestinationIp) \n| where SourceIp in (IPList) or DestinationIp in (IPList) \n| extend IPMatch = case( SourceIp in (IPList), "SourceIP", DestinationIp in (IPList), "DestinationIP", "None") \n| extend timestamp = TimeGenerated , IPCustomEntity = case(IPMatch == "SourceIP", SourceIp, IPMatch == "DestinationIP", DestinationIp, "None"), Host = Computer\n),\n(Event\n| where Source == "Microsoft-Windows-Sysmon"\n| where EventID == 3\n| extend EvData = parse_xml(EventData)\n| extend EventDetail = EvData.DataItem.EventData.Data\n| extend SourceIP = EventDetail.[9].["#text"], DestinationIP = EventDetail.[14].["#text"]\n| where SourceIP in (IPList) or DestinationIP in (IPList) \n| extend IPMatch = case( SourceIP in (IPList), "SourceIP", DestinationIP in (IPList), "DestinationIP", "None") \n| extend timestamp = TimeGenerated, AccountCustomEntity = UserName, HostCustomEntity = Computer , IPCustomEntity = case(IPMatch == "SourceIP", SourceIP, IPMatch == "DestinationIP", DestinationIP, "None")\n),\n(SigninLogs\n| where isnotempty(IPAddress)\n| where IPAddress in (IPList)\n| extend timestamp = TimeGenerated, AccountCustomEntity = UserPrincipalName, IPCustomEntity = IPAddress\n),\n(AADNonInteractiveUserSignInLogs\n| where isnotempty(IPAddress)\n| where IPAddress in (IPList)\n| extend timestamp = TimeGenerated, AccountCustomEntity = UserPrincipalName, IPCustomEntity = IPAddress\n),\n(W3CIISLog \n| where isnotempty(cIP)\n| where cIP in (IPList)\n| extend timestamp = TimeGenerated, IPCustomEntity = cIP, HostCustomEntity = Computer, AccountCustomEntity = csUserName\n),\n(AzureActivity \n| where isnotempty(CallerIpAddress)\n| where CallerIpAddress in (IPList)\n| extend timestamp = TimeGenerated, IPCustomEntity = CallerIpAddress, AccountCustomEntity = Caller\n),\n(\nAWSCloudTrail\n| where isnotempty(SourceIpAddress)\n| where SourceIpAddress in (IPList)\n| extend timestamp = TimeGenerated, IPCustomEntity = SourceIpAddress, AccountCustomEntity = UserIdentityUserName\n),\n(\nAzureDiagnostics\n| where ResourceType == "AZUREFIREWALLS"\n| where Category == "AzureFirewallApplicationRule"\n| parse msg_s with Protocol \'request from \' SourceHost \':\' SourcePort \'to \' DestinationHost \':\' DestinationPort \'. Action:\' Action\n| where isnotempty(DestinationHost)\n| where DestinationHost has_any (IPList)  \n| extend DestinationIP = DestinationHost \n| extend IPCustomEntity = SourceHost\n),\n(\nAzureDiagnostics\n| where ResourceType == "AZUREFIREWALLS"\n| where Category == "AzureFirewallNetworkRule"\n| parse msg_s with Protocol \'request from \' SourceHost \':\' SourcePort \'to \' DestinationHost \':\' DestinationPort \'. Action:\' Action\n| where isnotempty(DestinationHost)\n| where DestinationHost has_any (IPList)  \n| extend DestinationIP = DestinationHost \n| extend IPCustomEntity = SourceHost\n)\n)'
    queryFrequency: 'P1D'
    queryPeriod: 'P1D'
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
    suppressionDuration: 'PT5H'
    suppressionEnabled: false
    tactics: [
      'CommandAndControl'
    ]
    alertRuleTemplateName: '7ee72a9e-2e54-459c-bc8a-8c08a6532a63'
    incidentConfiguration: {
      createIncident: true
      groupingConfiguration: {
        enabled: false
        reopenClosedIncident: false
        lookbackDuration: 'PT5H'
        matchingMethod: 'AllEntities'
        groupByEntities: []
        groupByAlertDetails: []
        groupByCustomDetails: []
      }
    }
    eventGroupingSettings: {
      aggregationKind: 'SingleAlert'
    }
    alertDetailsOverride: {
      alertDisplayNameFormat: 'Known IRIDIUM IP: {{IPCustomEntity}}'
      alertDescriptionFormat: 'Alert generated at {{TimeGenerated}}'
      alertTacticsColumnName: null
      alertSeverityColumnName: 'Severity'
    }
    
    entityMappings: [
      {
        entityType: 'Account'
        fieldMappings: [
          {
            identifier: 'FullName'
            columnName: 'AccountCustomEntity'
          }
        ]
      }
      {
        entityType: 'Host'
        fieldMappings: [
          {
            identifier: 'FullName'
            columnName: 'HostCustomEntity'
          }
        ]
      }
      {
        entityType: 'IP'
        fieldMappings: [
          {
            identifier: 'Address'
            columnName: 'IPCustomEntity'
          }
        ]
      }
    ]
  }
}
