param votingWebAppIdentityPrincipalId string
param votingCounterFunctionIdentityPrincipalId string
param keyVaultName string

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2025-05-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: votingWebAppIdentityPrincipalId
        permissions: {
          keys: []
          secrets: [
            'Get'
          ]
          certificates: []
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: votingCounterFunctionIdentityPrincipalId
        permissions: {
          keys: []
          secrets: [
            'Get'
          ]
          certificates: []
        }
      }
    ]
  }
}
