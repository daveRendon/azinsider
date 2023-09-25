@minLength(1)
@maxLength(80)
param nsgName string
param securityRules array = []
param location string = resourceGroup().location


resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
}

module securityRulesLoop 'nsgrules.bicep' = [for (rule, index) in securityRules: {
  name: 'securityRule${index}Deployment-${uniqueString(deployment().name)}'
  params: {
    nsgName: nsg.name
    ruleName: rule.ruleName
    description: rule.description
    access: rule.access
    protocol: rule.protocol
    direction: rule.direction
    priority: rule.priority
    sourceAddressPrefix: rule.sourceAddressPrefix
    sourcePortRange: rule.sourcePortRange
    destinationAddressPrefix: rule.destinationAddressPrefix
    destinationPortRange: rule.destinationPortRange
  }
}]
