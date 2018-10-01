require 'coinbase_commerce'
module Spree
  class PaymentMethod::CoinbaseCommercePayment < PaymentMethod
    preference :api_key, :string
    preference :api_version, :string
    preference :webhook_secret, :string

    def create_client
      CoinbaseCommerce::Client.new(api_key: get_preference(:api_key),
                                   api_ver: get_preference(:api_version))
    end

    def api_uri
      "https://api.commerce.coinbase.com"
    end
  end
end