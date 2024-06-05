using 'main.bicep'

param sqlServerName = 'azinsdr-sql'

param keyVaultName = 'azinsdr-kv'

param functionAppName = 'azinsdr-fnapp'

param secretName = 'sqlPassword'

param repoURL = 'https://github.com/daveRendon/KeyVault-Rotation.git'
