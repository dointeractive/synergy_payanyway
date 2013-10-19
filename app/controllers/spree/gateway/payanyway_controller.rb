class Spree::Gateway::PayanywayController < Spree::StoreController
  skip_before_filter :verify_authenticity_token, :only => [:result, :success, :fail]

  before_filter :load_order, :only => [:result, :success, :fail]

  # def show
  #   @order =  Spree::Order.find(params[:order_id])
  #   @gateway = @order.available_payment_methods.find{|x| x.id == params[:gateway_id].to_i }

  #   if @order.blank? || @gateway.blank?
  #     flash[:error] = I18n.t('invalid_arguments')
  #     redirect_to :back
  #   else
  #     @signature = Digest::MD5.hexdigest([ @gateway.options[:id], @order.id, format("%.2f", @order.total), @gateway.options[:currency_code], @gateway.mode, @gateway.options[:signature] ].join)
  #   end
  # end

  def result
    if @gateway.result_signature(@order, params) == params['MNT_SIGNATURE'] && complete_or_create_payment(@order, @gateway, params) && complete_order(@order)
      render :text => 'SUCCESS'
    else
      render :text => 'FAIL'
    end
  end

  def success
    if @order && complete_order(@order)
      session[:order_id] = nil
      redirect_to account_orders_url, :notice => Spree.t(:order_processed_successfully)
    else
      flash[:error] = Spree.t(:payment_fail)
      redirect_to account_orders_url
    end
  end

  def fail
    flash[:error] = Spree.t(:payment_fail)
    redirect_to @order.blank? ? account_orders_url : checkout_state_url('payment')
  end

  private

  def load_order
    @order = Spree::Order.find_by_number(params['MNT_TRANSACTION_ID'])
    @gateway = Spree::PaymentMethod.available.detect{ |pm| pm.kind_of? Spree::Gateway::Payanyway }
  end
  
  def complete_or_create_payment(order, gateway, api_params)
    return unless order && gateway
    amount = api_params['MNT_AMOUNT'].to_f
    payment = order.payments.detect{ |p| p.payment_method == @gateway && p.amount == amount }
    return true if payment && payment.completed?
    if !payment
      order.payments.where(:state => ['checkout', 'pending', 'processing']).destroy_all
      payment = order.payments.create({:payment_method_id => gateway.id, :amount => amount})
    end
    payment.complete && order.update!
  end

  def complete_order(order)
    unless order.complete?
      order.next! until order.state == 'complete'
    end
    order.complete?
  end

end