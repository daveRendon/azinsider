using 'main.bicep'

param location = 'southcentralus'

param vm_name = 'GEN-UNIQUE-8'

param adminUsername = 'GEN-UNIQUE'

param adminPassword = 'GEN-PASSWORD'

param virtualNetwork_name = 'GEN-VNET-NAME'

param nic_name = 'GEN-UNIQUE-8'

param publicIPAddress_name = 'GEN-UNIQUE-8'

param dnsprefix = 'GEN-UNIQUE-13'

param networkSecurityGroup_name = 'GEN-UNIQUE-8'

param scriptFileName = 'ChocoInstall.ps1'

param chocoPackages = 'obs-studio;skype;obs-ndi'
