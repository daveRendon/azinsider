🚀 **AzInsider - Azure Application Deployment Repository with Bicep**

Welcome to the AzInsider repository – your gateway to deploying diverse workloads effortlessly in your Azure environment using the power of Bicep language.

🌟 **Key Features:**

- 📂 Explore the [application-workloads directory](https://github.com/daveRendon/azinsider/tree/main/application-workloads) for a rich collection of real-world application samples.
- 💡 Contribute and make your mark in the Azure community!

🚀 **Get Started with Bicep:**

1. **Begin by [installing the necessary tooling](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install?WT.mc_id=AZ-MVP-5000671).**
2. **Master Bicep with the [Bicep Learning Path](https://docs.microsoft.com/learn/paths/bicep-deploy?WT.mc_id=AZ-MVP-5000671).**

📦 **Deployment Options:**

**Option 1. Local Machine Deployment:**

Deploy application samples directly from your local machine using Windows Terminal and Azure PowerShell.

```powershell
$date = Get-Date -Format "MM-dd-yyyy"
$rand = Get-Random -Maximum 1000
$deploymentName = "AzInsiderDeployment-"+"$date"+"-"+"$rand"

New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName azinsider_demo -TemplateFile .\main.bicep -TemplateParameterFile .\azuredeploy.parameters.json -c
```

You can also utilize a Bicep parameters file for added flexibility.

**Option 2. Azure Portal Deployment:**

1. Access the Azure Portal, open CloudShell (using PowerShell), and clone this repository:

```shell
git clone https://github.com/daveRendon/azinsider.git
cd azinsider
cd application-workloads
```

2. Once in the working directory of the sample application, execute the following command:

```powershell
$date = Get-Date -Format "MM-dd-yyyy"
$rand = Get-Random -Maximum 1000
$deploymentName = "AzInsiderDeployment-"+"$date"+"-"+"$rand"

New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName azinsider_demo -TemplateFile .\main.bicep -TemplateParameterFile .\azuredeploy.parameters.json -c
```

Join us in simplifying Azure deployments with Bicep and unleash the full potential of your cloud projects! 🔥