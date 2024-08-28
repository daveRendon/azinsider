@description('Name of App Service plan')
param HostingPlanName string = guid(resourceGroup().id)

@description('The pricing tier for the App Service plan')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param HostingPlanSku string = 'B3'

@description('Name of Web App')
param WebsiteName string = guid(resourceGroup().id)

@description('Name of Application Insights')
param ApplicationInsightsName string = guid(resourceGroup().id)

@description('Name of Azure Search Service')
param AzureSearchService string = ''

@description('Name of Azure Search Index')
param AzureSearchIndex string = ''

@description('Azure Search Admin Key')
@secure()
param AzureSearchKey string = ''

@description('Use semantic search')
param AzureSearchUseSemanticSearch bool = false

@description('Semantic search config')
param AzureSearchSemanticSearchConfig string = 'default'

@description('Is the index prechunked')
param AzureSearchIndexIsPrechunked bool = false

@description('Top K results')
param AzureSearchTopK int = 5

@description('Enable in domain')
param AzureSearchEnableInDomain bool = false

@description('Content columns')
param AzureSearchContentColumns string = 'content'

@description('Filename column')
param AzureSearchFilenameColumn string = 'filename'

@description('Title column')
param AzureSearchTitleColumn string = 'title'

@description('Url column')
param AzureSearchUrlColumn string = 'url'

@description('Name of Azure OpenAI Resource')
param AzureOpenAIResource string

@description('Azure OpenAI Model Deployment Name')
param AzureOpenAIModel string

@description('Azure OpenAI Model Name')
param AzureOpenAIModelName string = 'gpt-35-turbo'

@description('Azure OpenAI Key')
@secure()
param AzureOpenAIKey string

@description('Azure OpenAI Temperature')
param AzureOpenAITemperature int = 0

@description('Azure OpenAI Top P')
param AzureOpenAITopP int = 1

@description('Azure OpenAI Max Tokens')
param AzureOpenAIMaxTokens int = 1000

@description('Azure OpenAI Stop Sequence')
param AzureOpenAIStopSequence string = '\n'

@description('Azure OpenAI System Message')
param AzureOpenAISystemMessage string = 'You are an AI assistant that helps people find information.'

@description('Whether or not to stream responses from Azure OpenAI')
param AzureOpenAIStream bool = true

@description('Azure Search Query Type')
@allowed([
  'simple'
  'semantic'
  'vector'
  'vectorSimpleHybrid'
  'vectorSemanticHybrid'
])
param AzureSearchQueryType string = 'simple'

@description('Azure Search Vector Fields')
param AzureSearchVectorFields string = ''

@description('Azure Search Permitted Groups Field')
param AzureSearchPermittedGroupsField string = ''

@description('Azure Search Strictness')
@allowed([
  1
  2
  3
  4
  5
])
param AzureSearchStrictness int = 3

@description('Azure OpenAI Embedding Deployment Name')
param AzureOpenAIEmbeddingName string = ''

@description('Enable chat history by deploying a Cosmos DB instance')
param WebAppEnableChatHistory bool = false

@description('Endpoint to use to connect to an Elasticsearch cluster')
param ElasticsearchEndpoint string = ''

@description('Encoded API key credentials to use to connect to an Elasticsearch cluster')
@secure()
param ElasticsearchEncodedApiKey string = ''

@description('Elasticsearch index to use for retrieving grounding data')
param ElasticsearchIndex string = ''

@description('Type of query to use for Elasticsearch data')
param ElasticsearchQueryType string = 'simple'

@description('Elasticsearch index content columns')
param ElasticsearchContentColumns string = ''

@description('Elasticsearch index filename column')
param ElasticsearchFilenameColumn string = ''

@description('Elasticsearch index title column')
param ElasticsearchTitleColumn string = ''

@description('Elasticsearch index url column')
param ElasticsearchUrlColumn string = ''

@description('Elasticsearch index vector columns')
param ElasticsearchVectorColumns string = ''

@description('Top K results')
param ElasticsearchTopK int = 5

@description('Enable in domain')
param ElasticsearchEnableInDomain bool = false

@description('Elasticsearch strictness')
@allowed([
  1
  2
  3
  4
  5
])
param ElasticsearchStrictness int = 3

@description('The model ID for a model deployed on Elasticsearch to use for generating embeddings for queries.')
param ElasticsearchEmbeddingModelId string = ''

var WebAppImageName = 'DOCKER|sampleappaoaichatgpt.azurecr.io/sample-app-aoai-chatgpt:latest'
var cosmosdb_account_name_var = 'db-${WebsiteName}'
var cosmosdb_database_name = 'db_conversation_history'
var cosmosdb_container_name = 'conversations'
var roleDefinitionId = '00000000-0000-0000-0000-000000000002'
var roleAssignmentId = guid(roleDefinitionId, WebsiteName, cosmosdb_account_name.id)

resource HostingPlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: HostingPlanName
  location: resourceGroup().location
  sku: {
    name: HostingPlanSku
  }
  properties: {
    name: HostingPlanName
    reserved: true
  }
  kind: 'linux'
}

resource Website 'Microsoft.Web/sites@2020-06-01' = {
  name: WebsiteName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: HostingPlanName
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(ApplicationInsights.id, '2015-05-01').InstrumentationKey
        }
        {
          name: 'AZURE_SEARCH_SERVICE'
          value: AzureSearchService
        }
        {
          name: 'AZURE_SEARCH_INDEX'
          value: AzureSearchIndex
        }
        {
          name: 'AZURE_SEARCH_KEY'
          value: AzureSearchKey
        }
        {
          name: 'AZURE_SEARCH_USE_SEMANTIC_SEARCH'
          value: AzureSearchUseSemanticSearch
        }
        {
          name: 'AZURE_SEARCH_SEMANTIC_SEARCH_CONFIG'
          value: AzureSearchSemanticSearchConfig
        }
        {
          name: 'AZURE_SEARCH_INDEX_IS_PRECHUNKED'
          value: AzureSearchIndexIsPrechunked
        }
        {
          name: 'AZURE_SEARCH_TOP_K'
          value: AzureSearchTopK
        }
        {
          name: 'AZURE_SEARCH_ENABLE_IN_DOMAIN'
          value: AzureSearchEnableInDomain
        }
        {
          name: 'AZURE_SEARCH_CONTENT_COLUMNS'
          value: AzureSearchContentColumns
        }
        {
          name: 'AZURE_SEARCH_FILENAME_COLUMN'
          value: AzureSearchFilenameColumn
        }
        {
          name: 'AZURE_SEARCH_TITLE_COLUMN'
          value: AzureSearchTitleColumn
        }
        {
          name: 'AZURE_SEARCH_URL_COLUMN'
          value: AzureSearchUrlColumn
        }
        {
          name: 'AZURE_OPENAI_RESOURCE'
          value: AzureOpenAIResource
        }
        {
          name: 'AZURE_OPENAI_MODEL'
          value: AzureOpenAIModel
        }
        {
          name: 'AZURE_OPENAI_KEY'
          value: AzureOpenAIKey
        }
        {
          name: 'AZURE_OPENAI_MODEL_NAME'
          value: AzureOpenAIModelName
        }
        {
          name: 'AZURE_OPENAI_TEMPERATURE'
          value: AzureOpenAITemperature
        }
        {
          name: 'AZURE_OPENAI_TOP_P'
          value: AzureOpenAITopP
        }
        {
          name: 'AZURE_OPENAI_MAX_TOKENS'
          value: AzureOpenAIMaxTokens
        }
        {
          name: 'AZURE_OPENAI_STOP_SEQUENCE'
          value: AzureOpenAIStopSequence
        }
        {
          name: 'AZURE_OPENAI_SYSTEM_MESSAGE'
          value: AzureOpenAISystemMessage
        }
        {
          name: 'AZURE_OPENAI_STREAM'
          value: AzureOpenAIStream
        }
        {
          name: 'AZURE_SEARCH_QUERY_TYPE'
          value: AzureSearchQueryType
        }
        {
          name: 'AZURE_SEARCH_VECTOR_COLUMNS'
          value: AzureSearchVectorFields
        }
        {
          name: 'AZURE_SEARCH_PERMITTED_GROUPS_COLUMN'
          value: AzureSearchPermittedGroupsField
        }
        {
          name: 'AZURE_SEARCH_STRICTNESS'
          value: AzureSearchStrictness
        }
        {
          name: 'AZURE_OPENAI_EMBEDDING_NAME'
          value: AzureOpenAIEmbeddingName
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'AZURE_COSMOSDB_ACCOUNT'
          value: (WebAppEnableChatHistory ? cosmosdb_account_name_var : '')
        }
        {
          name: 'AZURE_COSMOSDB_DATABASE'
          value: cosmosdb_database_name
        }
        {
          name: 'AZURE_COSMOSDB_CONVERSATIONS_CONTAINER'
          value: cosmosdb_container_name
        }
        {
          name: 'ELASTICSEARCH_ENDPOINT'
          value: ElasticsearchEndpoint
        }
        {
          name: 'ELASTICSEARCH_ENCODED_API_KEY'
          value: ElasticsearchEncodedApiKey
        }
        {
          name: 'ELASTICSEARCH_INDEX'
          value: ElasticsearchIndex
        }
        {
          name: 'ELASTICSEARCH_QUERY_TYPE'
          value: ElasticsearchQueryType
        }
        {
          name: 'ELASTICSEARCH_TOP_K'
          value: ElasticsearchTopK
        }
        {
          name: 'ELASTICSEARCH_ENABLE_IN_DOMAIN'
          value: ElasticsearchEnableInDomain
        }
        {
          name: 'ELASTICSEARCH_CONTENT_COLUMNS'
          value: ElasticsearchContentColumns
        }
        {
          name: 'ELASTICSEARCH_FILENAME_COLUMN'
          value: ElasticsearchFilenameColumn
        }
        {
          name: 'ELASTICSEARCH_TITLE_COLUMN'
          value: ElasticsearchTitleColumn
        }
        {
          name: 'ELASTICSEARCH_URL_COLUMN'
          value: ElasticsearchUrlColumn
        }
        {
          name: 'ELASTICSEARCH_VECTOR_COLUMNS'
          value: ElasticsearchVectorColumns
        }
        {
          name: 'ELASTICSEARCH_STRICTNESS'
          value: ElasticsearchStrictness
        }
        {
          name: 'ELASTICSEARCH_EMBEDDING_MODEL_ID'
          value: ElasticsearchEmbeddingModelId
        }
        {
          name: 'UWSGI_PROCESSES'
          value: '2'
        }
        {
          name: 'UWSGI_THREADS'
          value: '2'
        }
      ]
      linuxFxVersion: WebAppImageName
    }
  }
  dependsOn: [
    HostingPlan
  ]
}

resource ApplicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: ApplicationInsightsName
  location: resourceGroup().location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites',ApplicationInsightsName)}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

resource cosmosdb_account_name 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = if (WebAppEnableChatHistory) {
  name: cosmosdb_account_name_var
  location: resourceGroup().location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: resourceGroup().location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource cosmosdb_account_name_cosmosdb_database_name 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = if (WebAppEnableChatHistory) {
  parent: cosmosdb_account_name
  name: '${cosmosdb_database_name}'
  properties: {
    resource: {
      id: cosmosdb_database_name
    }
  }
}

resource cosmosdb_account_name_cosmosdb_database_name_conversations 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (WebAppEnableChatHistory) {
  parent: cosmosdb_account_name_cosmosdb_database_name
  name: 'conversations'
  properties: {
    resource: {
      id: 'conversations'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/userId'
        ]
        kind: 'Hash'
      }
    }
  }
  dependsOn: [
    cosmosdb_account_name
  ]
}

resource cosmosdb_account_name_roleAssignmentId 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-04-15' = if (WebAppEnableChatHistory) {
  parent: cosmosdb_account_name
  name: '${roleAssignmentId}'
  properties: {
    roleDefinitionId: resourceId(
      'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions',
      split('${cosmosdb_account_name_var}/${roleDefinitionId}', '/')[0],
      split('${cosmosdb_account_name_var}/${roleDefinitionId}', '/')[1]
    )
    principalId: reference(Website.id, '2021-02-01', 'Full').identity.principalId
    scope: cosmosdb_account_name.id
  }
}
