using 'main.bicep'

param name = 'azinsider-lang'

param sku = 'F0'

param ipRules = []

param virtualNetworkType = 'None'

param identity = {
  type: 'None'
}
