param nsgName string
param ruleName string
param description string
param access string
param protocol string
param direction string
param priority int
param sourceAddressPrefix string
param sourcePortRange string
param destinationAddressPrefix string
param destinationPortRange string


resource nsg 'Microsoft.Network/networkSecurityGroups@2021-08-01' existing = {
  name: nsgName
}

resource securityRule 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  parent: nsg
  name: ruleName
  properties: {
    description: description
    access: access
    protocol: protocol
    direction: direction
    priority: priority
    sourceAddressPrefix: sourceAddressPrefix
    sourcePortRange: sourcePortRange
    destinationAddressPrefix: destinationAddressPrefix
    destinationPortRange: destinationPortRange
  }
}
