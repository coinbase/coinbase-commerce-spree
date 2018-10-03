require 'coinbase_commerce'
module Spree
  class CoinbaseCommerceController < StoreController
    skip_before_action :verify_authenticity_token

    def notify
      payload = request.body.read
      sig_header = request.env['HTTP_X_CC_WEBHOOK_SIGNATURE']
      begin
        payment = Spree::PaymentMethod.find_by(type: "Spree::PaymentMethod::CoinbaseCommercePayment")
        webhook_secret = payment.get_preference(:webhook_secret)
        event = CoinbaseCommerce::Webhook.construct_event(payload, sig_header, webhook_secret)
        puts "Received event id=#{event.id}, type=#{event.type}"
        payments = event.data.payments
        if payments.any?
          payment_status = payments.last.status
        else
          payment_status = nil
        end
        if payment_status=="CONFIRMED" || payment_status=="COMPLETED"
          # Fetch Spree order information, find relevant payment
          order_id = event.data.metadata.order_id
          payment_id = event.data.metadata.payment_id
          order = Spree::Order.find(order_id)
          payment = order.payments.find(payment_id)
          payment.complete!
          # set order state to complete
          order.next
          # set shipping state to complete
          order.finalize!
          session[:order_id] = nil
        end
        head :ok
      rescue JSON::ParserError
        head :uprocessable_entity
        return
      rescue CoinbaseCommerce::Errors::SignatureVerificationError
        head :uprocessable_entity
        return
      rescue CoinbaseCommerce::Errors::WebhookInvalidPayload
        head :uprocessable_entity
        return
      end
    end
  end
end
