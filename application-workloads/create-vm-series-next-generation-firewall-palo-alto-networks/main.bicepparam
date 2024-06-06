using 'main.bicep'

param location = 'eastus'

param publicIPAddressName = 'azinsider'

param publicIPNewOrExisting = 'new'

param publicIPAllocationMethod = 'Dynamic'

param publicIPRGName = 'azinsider_demo'

param vmName = 'azinsider'

param adminUsername = 'azureuser'

param authenticationType = 'password'

param adminPasswordOrKey = 'YOUR-ADMIN-PASSWD'

param vmSize = 'Standard_D3_v2'

param imageVersion = 'latest'

param srcIPInboundNSG = '0.0.0.0/0'

param virtualNetworkName = 'fwVNET'

param virtualNetworkExistingRGName = 'azinsider_demo'

param virtualNetworkAddressPrefixes = [
  '10.0.0.0/16'
]

param vnetNewOrExisting = 'new'

param subnet0Name = 'Mgmt'

param subnet1Name = 'Untrust'

param subnet2Name = 'Trust'

param subnet0Prefix = '10.0.0.0/24'

param subnet1Prefix = '10.0.1.0/24'

param subnet2Prefix = '10.0.2.0/24'

param subnet1StartAddress = '10.0.1.4'

param subnet2StartAddress = '10.0.2.4'

param bootstrap = 'no'

param customData = 'storage-account=None,access-key=None,file-share=None,share-directory=None'
