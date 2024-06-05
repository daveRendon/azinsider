using 'main.bicep'

param functionAppName = 'azinsiderfun'

param location = 'East US'

param hostingPlanName = 'ASP-azinsiderdemo-ba3e'

param alwaysOn = true

param ftpsState = 'FtpsOnly'

param storageAccountName = 'azinsiderdemob924'

param sku = 'PremiumV2'

param skuCode = 'P1v2'

param use32BitWorkerProcess = false

param linuxFxVersion = 'PowerShell|7.2'
