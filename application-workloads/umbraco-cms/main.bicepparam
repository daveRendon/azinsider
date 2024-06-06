using 'main.bicep'

param appName = 'azinsider-app'

param redisCacheName = 'azinsider-redis'

param storageAccountType = 'Standard_GRS'

param dbServerName = 'azinsiderdbserver'

param dbName = 'azinsiderdb'

param dbAdministratorLogin = 'umbracouseradmin'

param dbAdministratorLoginPassword = 'Your-passwrd'

param nonAdminDatabaseUsername = 'azureuser'

param nonAdminDatabasePassword = 'Your-passwrd'

param actionGroupName = 'azinsideractiongroup'

param actionGroupShortName = 'acg'

param emails = [
  'Your-admin-email'
]

param packageUri = 'https://auxmktplceprod.blob.core.windows.net/packages/ScalableUmbracoCms.WebPI.7.4.3.zip'
