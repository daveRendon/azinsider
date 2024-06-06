using 'main.bicep'

param adminUsername = 'Student'

param adminPassword = 'Pa55w.rd1234'

param vmNamePrefix = 'az104-10-vm'

param nicNamePrefix = 'az104-10-nic'

param imagePublisher = 'MicrosoftWindowsServer'

param imageOffer = 'WindowsServer'

param imageSKU = '2019-Datacenter'

param vmSize = 'Standard_D2s_v3'

param virtualNetworkName = 'az104-10-vnet'

param addressPrefix = '10.0.0.0/24'

param virtualNetworkResourceGroup = 'az104-10-rg0'

param subnet0Name = 'subnet0'

param subnet0Prefix = '10.0.0.0/26'
