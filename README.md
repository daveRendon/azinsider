# AzInsider - Azure Application Deployment Repository with Bicep

[![Azure](https://img.shields.io/badge/Azure-Bicep-0078D4?logo=microsoftazure&logoColor=white)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview?WT.mc_id=AZ-MVP-5000671)
[![License](https://img.shields.io/github/license/daveRendon/azinsider)](LICENSE)
[![Stars](https://img.shields.io/github/stars/daveRendon/azinsider?style=social)](https://github.com/daveRendon/azinsider/stargazers)

Your gateway to deploying diverse workloads effortlessly in Azure using the power of [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview?WT.mc_id=AZ-MVP-5000671). This repository contains **96+ production-ready samples** covering AI, networking, security, containers, serverless, and more.

> **Star** this repository to stay updated and show your support for the project.

---

## Sample Categories

Browse the [application-workloads](https://github.com/daveRendon/azinsider/tree/main/application-workloads) directory for the full collection, organized across these areas:

| Category | Examples |
|---|---|
| **AI & Machine Learning** | Azure OpenAI, ChatGPT, AI Studio, Computer Vision, DeepSeek R1, Data Science VM |
| **Networking & Security** | Azure Firewall, VNet Peering, Hub-Spoke, Front Door, Load Balancer, NSGs |
| **Identity & Governance** | Microsoft Sentinel, Defender for Cloud, Active Directory, Key Vault Rotation |
| **Containers & Kubernetes** | AKS, AKS Baseline, Container Apps, Docker Swarm, Container Registry |
| **Web Applications** | App Service, Static Web Apps, WordPress, Django, Umbraco, N-Tier Architecture |
| **Serverless & Integration** | Azure Functions, Logic Apps, API Management, Event Grid |
| **Data & Analytics** | Databricks, Purview, MongoDB, PostgreSQL |
| **Monitoring** | Managed Grafana, Prometheus |

---

## Prerequisites

- An active [Azure subscription](https://azure.microsoft.com/free/?WT.mc_id=AZ-MVP-5000671)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli?WT.mc_id=AZ-MVP-5000671) or [Azure PowerShell](https://learn.microsoft.com/powershell/azure/install-azure-powershell?WT.mc_id=AZ-MVP-5000671)
- [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install?WT.mc_id=AZ-MVP-5000671) (included with Azure CLI v2.20.0+)

## Getting Started with Bicep

1. [Install the Bicep tooling](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install?WT.mc_id=AZ-MVP-5000671)
2. Complete the [Bicep Learning Path](https://learn.microsoft.com/training/paths/bicep-deploy?WT.mc_id=AZ-MVP-5000671)

---

## Deployment Options

### Option 1: Local Machine

Deploy from your local machine using Azure PowerShell:

```powershell
$date = Get-Date -Format "MM-dd-yyyy"
$rand = Get-Random -Maximum 1000
$deploymentName = "AzInsiderDeployment-"+"$date"+"-"+"$rand"

New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName azinsider_demo -TemplateFile .\main.bicep -TemplateParameterFile .\azuredeploy.parameters.json -c
```

Or using Azure CLI:

```bash
az deployment group create \
  --resource-group azinsider_demo \
  --template-file main.bicep \
  --parameters @azuredeploy.parameters.json \
  --confirm-with-what-if
```

> You can also use a `.bicepparam` file instead of a JSON parameters file for a more concise syntax.

### Option 2: Azure Cloud Shell

1. Open [Cloud Shell](https://shell.azure.com) (PowerShell) and clone the repository:

```shell
git clone https://github.com/daveRendon/azinsider.git
cd azinsider/application-workloads
```

2. Navigate to the sample you want to deploy:

```shell
cd chatgpt-base
```

3. Run the deployment:

```powershell
$date = Get-Date -Format "MM-dd-yyyy"
$rand = Get-Random -Maximum 1000
$deploymentName = "AzInsiderDeployment-"+"$date"+"-"+"$rand"

New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName azinsider_demo -TemplateFile .\main.bicep -TemplateParameterFile .\azuredeploy.parameters.json -c
```

---

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before submitting a pull request.

## License

This project is licensed under the terms of the [MIT License](LICENSE).