---
title: Concepts
geekdocNav: true
geekdocAlign: left
geekdocAnchor: true
---

This section lists important concepts Azure Bicep Language on.

Azure Bicep streamlines the deployment of Azure resources through its declarative syntax, which outlines the desired state of resources without specifying the step-by-step process to achieve it. Here's a breakdown of its main concepts with samples:

1. **Declarative Syntax**: Bicep simplifies Azure resource deployment with its clear and concise syntax. For example:

```bicep
resource myStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'mystorageaccount'
  location: 'eastus'
  sku: {
    name: 'Standard_LRS'
  }
}
```

2. **Resource Declaration**: Resources are defined using resource blocks, specifying type, name, and properties. Here's a sample:

```bicep
resource myAppService 'Microsoft.Web/sites@2021-01-01' = {
  name: 'myappservice'
  location: 'westus'
  properties: {
    serverFarmId: myAppServicePlan.id
  }
}
```

3. **Expressions**: Bicep supports expressions for dynamic value generation. For example:

```bicep
var storageAccountName = 'mystorageaccount'
resource myStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  // other properties
}
```

4. **Parameters and Variables**: Parameters allow runtime customization, while variables enable value reuse. Example:

```bicep
param location string = 'westus'
var resourceGroupName = 'myResourceGroup'
```

5. **Modules**: Modularization is achieved through modules, promoting code reuse. Sample usage:

```bicep
module mySubnet 'subnets.bicep' = {
  name: 'subnetModule'
  params: {
    subnetName: 'mySubnet'
    addressPrefix: '10.0.0.0/24'
  }
}
```

6. **Output Declaration**: Outputs expose important values post-deployment. Example:

```bicep
output storageAccountConnectionString string = myStorageAccount.properties.primaryEndpoints.blob
```

7. **Conditions and Loops**: Bicep supports conditional logic and loops for dynamic deployments. Sample usage:

```bicep
for i in range(5) {
  resource myVMs[i] 'Microsoft.Compute/virtualMachines@2021-04-01' = {
    name: 'myVM-${i}'
    // other properties
  }
}
```

In summary, Azure Bicep offers a straightforward approach to deploying Azure resources through its intuitive syntax, expressions, parameters, modules, outputs, and support for conditions and loops, enhancing the manageability and scalability of infrastructure deployments.
