using 'main.bicep'

param subscriptionId = 'xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx'

param name = 'azinsider'

param location = 'eastus'

param hostingPlanName = 'ASP-azinsidrgroup-a6b8'

param serverFarmResourceGroup = 'azinsider_demo'

param sku = 'PremiumV2'

param skuCode = 'P1v2'

param workerSize = '3'

param workerSizeId = '3'

param numberOfWorkers = '1'

param kind = 'linux'

param reserved = true

param alwaysOn = true

param linuxFxVersion = 'DOCKER|mcr.microsoft.com/appsvc/wordpress-alpine-php:latest'

param dockerRegistryUrl = 'https://mcr.microsoft.com'

param storageSizeGB = 128

param storageIops = 700

param storageAutoGrow = 'Enabled'

param backupRetentionDays = 7

param geoRedundantBackup = 'Disabled'

param vmName = 'Standard_D2ds_v4'

param serverEdition = 'GeneralPurpose'

param vCores = 2

param charset = 'utf8'

param collation = 'utf8_general_ci'

param serverName = 'azinsidr-f11bb8d5f4db45a685747f3dfa46d024-dbserver'

param serverUsername = 'ejkvvgbqlo'

param serverPassword = 'YourServerPassword'

param databaseName = 'azinsidr_f11bb8d5f4db45a685747f3dfa46d024_database'

param publicNetworkAccess = 'Disabled'

param wordpressTitle = 'WordPress On Azure'

param wordpressAdminEmail = 'Your-wordpress-admin-email'

param wordpressUsername = 'your-wordpress-username'

param wordpressPassword = 'YourWordPressPassword'

param wpLocaleCode = 'en_US'

param cdnProfileName = 'azinsidr-f72ddf40c97ef984e5ed-cdnprofile'

param cdnEndpointName = 'azinsidr-f72ddf40c97ef984e5ed-endpoint'

param cdnType = 'Standard_Microsoft'

param cdnEndpointProperties = {
  isHttpAllowed: true
  isHttpsAllowed: true
  originHostHeader: 'azinsidr.azurewebsites.net'
  origins: [
    {
      name: 'azinsidr-azurewebsites-net'
      properties: {
        hostName: 'azinsidr.azurewebsites.net'
        httpPort: 80
        httpsPort: 443
        originHostHeader: 'azinsidr.azurewebsites.net'
        priority: 1
        weight: 1000
        enabled: true
      }
    }
  ]
  isCompressionEnabled: true
  contentTypesToCompress: [
    'application/eot'
    'application/font'
    'application/font-sfnt'
    'application/javascript'
    'application/json'
    'application/opentype'
    'application/otf'
    'application/pkcs7-mime'
    'application/truetype'
    'application/ttf'
    'application/vnd.ms-fontobject'
    'application/xhtml+xml'
    'application/xml'
    'application/xml+rss'
    'application/x-font-opentype'
    'application/x-font-truetype'
    'application/x-font-ttf'
    'application/x-httpd-cgi'
    'application/x-javascript'
    'application/x-mpegurl'
    'application/x-opentype'
    'application/x-otf'
    'application/x-perl'
    'application/x-ttf'
    'font/eot'
    'font/ttf'
    'font/otf'
    'font/opentype'
    'image/svg+xml'
    'text/css'
    'text/csv'
    'text/html'
    'text/javascript'
    'text/js'
    'text/plain'
    'text/richtext'
    'text/tab-separated-values'
    'text/xml'
    'text/x-script'
    'text/x-component'
    'text/x-java-source'
  ]
}

param vnetName = 'azinsidr-436c376a86-vnet'

param subnetForApp = 'azinsidr-436c376a86-appsubnet'

param subnetForDb = 'azinsidr-436c376a86-dbsubnet'

param privateDnsZoneNameForDb = 'azinsidr-436c376a86-privatelink.mysql.database.azure.com'
