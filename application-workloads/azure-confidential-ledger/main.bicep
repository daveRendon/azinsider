@description('Ledger Name')
@minLength(3)
@maxLength(24)
param ledgerName string

@description('Oid of the user')
@secure()
param principalId string

@description('Location for all resources.')
param location string = resourceGroup().location

resource ledgerName_resource 'Microsoft.ConfidentialLedger/ledgers@2022-05-13' = {
  name: ledgerName
  location: location
  properties: {
    ledgerType: 'Public'
    aadBasedSecurityPrincipals: [
      {
        principalId: principalId
        ledgerRoleName: 'Administrator'
      }
    ]
  }
}
