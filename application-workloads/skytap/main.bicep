param planId string
param offerId string
param publisherId string
param quantity int
param termId string
param subscriptionId string
param riskPropertyBagHeader string
param autoRenew bool
param location string
param name string


resource skytap 'Microsoft.SaaS/resources@2018-03-01-beta' = {
  name: name
  location: location
  properties: {
    saasResourceName: name
    publisherId: publisherId
    SKUId: planId
    offerId: offerId
    quantity: quantity
    termId: termId
    autoRenew: autoRenew
    paymentChannelType: 'SubscriptionDelegated'
    paymentChannelMetadata: {
        AzureSubscriptionId: subscriptionId
    }
    storeFront: 'AzurePortal'
    riskPropertyBagHeader: riskPropertyBagHeader
}
}
