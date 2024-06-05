using 'main.bicep'

param cloudGuardVersion = 'R81.10 - Bring Your Own License'

param adminPassword = 'YOUR-ADMIN-PASS'

param authenticationType = 'password'

param vmName = 'azinsider'

param vmSize = 'Standard_D3_v2'

param virtualNetworkName = 'vnet01'

param virtualNetworkAddressPrefix = '10.0.0.0/20'

param Subnet1Name = 'Management'

param Subnet1Prefix = '10.0.0.0/24'

param Subnet1StartAddress = '10.0.0.4'

param vnetNewOrExisting = 'new'

param virtualNetworkExistingRGName = 'azinsider_demo'

param managementGUIClientNetwork = '10.0.0.0/24'

param installationType = 'management'

param bootstrapScript = ''

param allowDownloadFromUploadToCheckPoint = 'true'

param additionalDiskSizeGB = 0

param diskType = 'Standard_LRS'

param sourceImageVhdUri = 'noCustomUri'

param enableApi = 'management_only'

param adminShell = '/etc/cli.sh'
