# ☁️ AzInsider - Application Samples using Bicep Language

Within this repository, you'll discover invaluable references to source codes, showcasing the precise steps for deploying various workloads in your Azure environment.

Make sure to explore the [application-workloads](https://github.com/daveRendon/azinsider/tree/main/application-workloads) directory, and don't hesitate to dive in and contribute!

👉 [https://github.com/daveRendon/azinsider/tree/main/application-workloads](https://github.com/daveRendon/azinsider/tree/main/application-workloads)


## Get started with Bicep

To get going with Bicep:

1. **Start by [installing the tooling](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install?WT.mc_id=AZ-MVP-5000671).**
2. **Complete the [Bicep Learning Path](https://docs.microsoft.com/learn/paths/bicep-deploy?WT.mc_id=AZ-MVP-5000671)**

## To deploy the application samples 

### Option 1. Using your local machine

You can use Windows Terminal and Azure PowerShell to deploy the application samples

```
$date = Get-Date -Format "MM-dd-yyyy"
$rand = Get-Random -Maximum 1000
$deploymentName = "AzInsiderDeployment-"+"$date"+"-"+"$rand"

New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName azinsider_demo -TemplateFile .\main.bicep -TemplateParameterFile .\azuredeploy.parameters.json -c
```
You can also pass on a bicep parameters file.

### Option 2. Using the Azure Portal

 1. In the Azure Portal, open CloudShell (using PowerShell). THen, clone this repository 

```
git clone https://github.com/daveRendon/azinsider.git

cd azinsider

cd application-workloads
```


 2. Then, once you're in the working directory of the sample application, deploy it using the command below:

```
$date = Get-Date -Format "MM-dd-yyyy"
$rand = Get-Random -Maximum 1000
$deploymentName = "AzInsiderDeployment-"+"$date"+"-"+"$rand"

New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName azinsider_demo -TemplateFile .\main.bicep -TemplateParameterFile .\azuredeploy.parameters.json -c
```

