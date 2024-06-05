using 'main.bicep'

param adminUsername = 'azureuser'

param adminPassword = 'YourPasswordHere'

param dnsPrefix = 'azinsiderdmo'

param domainName = 'azinsider.local'

param location = 'eastus'

param _artifactsLocation = 'https://raw.githubusercontent.com/daveRendon/azure-quickstart-templates/master/application-workloads/active-directory/active-directory-new-domain-ha-2-dc-zones/'
