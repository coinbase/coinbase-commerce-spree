module Spree
  class CheckoutController < StoreController
    before_action :redirect_to_coinbase_commerce, only: :update

    def redirect_to_coinbase_commerce
      order = current_order || raise(ActiveRecord::RecordNotFound)
      if params[:state] == "payment"
        return unless params[:order][:payments_attributes]
        payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])

      elsif params[:state] == "confirm"
        payment_method = @order.payment_method
      end

      if !payment_method.nil? && payment_method.kind_of?(PaymentMethod::CoinbaseCommercePayment)
        client = payment_method.create_client
        payment = order.payments.create!(amount: order.total,
                                         payment_method: payment_method,
                                         order_id: order.id)
        payment.started_processing!
        charge_info = {
            "name": "Order #%s" % order.number,
            "description": "Spree order",
            "pricing_type": "fixed_price",
            "metadata": {
                "order_id": order.id,
                "payment_id": payment.id
            },
            "local_price": {
                "amount": order.total,
                "currency": order.currency
            },
            "redirect_url": "http://#{request.host}:#{request.port}/orders/#{order.number}"
        }
        charge = client.charge.create(charge_info)
        redirect_to "#{charge.hosted_url}"
      end
    end
  end
end


