using 'main.bicep'

param name = 'myfirstswadeployment'

param location = 'Central US'

param sku = 'Free'

param skucode = 'Free'

param repositoryUrl = 'https://github.com/<YOUR-GITHUB-USER-NAME>/<YOUR-GITHUB-REPOSITORY-NAME>'

param branch = 'main'

param repositoryToken = '<YOUR-GITHUB-PAT>'

param appLocation = '/'

param apiLocation = ''

param appArtifactLocation = 'src'

param resourceTags = {
  Environment: 'Development'
  Project: 'Testing SWA with Bicep'
  ApplicationName: 'myfirstswadeployment'
}

param appSettings = {
  MY_APP_SETTING1: 'value 1'
  MY_APP_SETTING2: 'value 2'
}
