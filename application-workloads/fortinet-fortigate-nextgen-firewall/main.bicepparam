using 'main.bicep'

param fortiGateNamePrefix = 'YOUR-FORTIGATE-NAME-PREFIX'

param fortiGateImageSKU = 'fortinet_fg-vm'

param fortiGateImageVersion = 'latest'

param adminUsername = 'YOUR-ADMIN-USERNAME'

param adminPassword = 'YOUR-PASSWORD'

param location = 'eastus'

param instanceType = 'Standard_F2s'

param acceleratedNetworking = 'true'

param publicIPNewOrExisting = 'new'

param publicIPName = 'FGTPublicIP'

param publicIPResourceGroup = 'YOUR-PUBLICIP-RESOURCE-GROUP'

param publicIPAddressType = 'Dynamic'

param vnetNewOrExisting = 'new'

param vnetName = 'FortiGate-VNET'

param vnetResourceGroup = 'YOUR-VNET-RESOURCE-GROUP'

param vnetAddressPrefix = '10.0.0.0/22'

param subnet1Name = 'ExternalSubnet'

param subnet1Prefix = '10.0.0.0/26'

param subnet1StartAddress = '10.0.0.4'

param subnet2Name = 'InternalSubnet'

param subnet2Prefix = '10.0.1.0/26'

param subnet2StartAddress = '10.0.1.4'

param subnet3Name = 'ProtectedSubnet'

param subnet3Prefix = '10.0.2.0/24'

param fortiManager = 'no'

param fortiManagerIP = ''

param fortiManagerSerial = ''

param fortiGateLicenseBYOL = ''

param fortiGateLicenseFlexVM = ''
