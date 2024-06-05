using 'main.bicep'

param location = 'eastus'

param functionAppName = 'azinsider'

param packageUri = 'https://github.com/daveRendon/azinsider/raw/main/application-workloads/azure-functions-dotnet-worker/azFunctionNetWorker.zip'

param netFrameworkVersion = 'v7.0'
