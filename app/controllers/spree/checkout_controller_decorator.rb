Spree::CheckoutController.class_eval do
  before_filter :redirect_to_payanyway_form_if_needed, :only => :update

  private

    def redirect_to_payanyway_form_if_needed
      return unless params[:state] == 'payment'
      payment_method = Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      if payment_method.kind_of? Spree::Gateway::Payanyway
        @order.update_attributes(object_params)
        @order.payments.last.started_processing!
        redirect_to payment_method.url_for_order(@order, params) and return
      end
    end
end
