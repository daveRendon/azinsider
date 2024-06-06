using 'main.bicep'

param name = 'azinsiderface'

param sku = 'F0'

param ipRules = []

param virtualNetworkType = 'None'

param identity = {
  type: 'None'
}
