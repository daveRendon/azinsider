using 'main.bicep'

param name = 'azinsider-chatgpt'

param location = 'eastus'

param principalId = 'e8cace21-41c9-4995-9ef2-aa4694cb3d8a'

param openAiResourceName = 'azinsider-OpenAI'

param openAiResourceGroupName = 'openai'

param openAiResourceGroupLocation = 'eastus'

param openAiSkuName = 'S0'

param createRoleForUser = true

param acaExists = false
