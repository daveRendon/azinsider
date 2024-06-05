using 'main.bicep'

param vmName = 'YOUR-VM-NAME'

param adminUsername = 'YOUR-VM-ADMIN-USERNAME'

param authenticationType = 'password'

param adminPasswordOrKey = 'YOUR-VM-PASSWORD-OR-KEY'

param dnsLabelPrefix = 'YOUR-VM-DNS-NAME'

param vmSize = 'Standard_B2s'

param virtualNetworkName = 'YOUR-VNET-NAME'

param subnetName = 'YOUR-VNET-subnet'

param networkSecurityGroupName = 'YOUR-NSG-NAME'
