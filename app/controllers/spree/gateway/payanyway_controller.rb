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
    if complete_or_create_payment(@order, @gateway)
      complete_order
      render :text => 'SUCCESS'
    else
      render :text => 'FAIL'
    end
  end

  def success
    if @order && @gateway && @order.complete?
      session[:order_id] = nil
      redirect_to after_success_path(@order), :notice => Spree.t(:order_processed_successfully)
    else
      flash[:error] = Spree.t(:payment_fail)
      redirect_to root_url
    end
  end

  def fail
    flash[:error] = Spree.t(:payment_fail)
    redirect_to @order.blank? ? root_url : checkout_state_url('payment')
  end

  protected

  def after_success_path(resource)
    account_orders_url
  end

  private

  def load_order
    @order = Spree::Order.find_by_id(params['MNT_TRANSACTION_ID'])
    @gateway = @order.payments.detect{|p| p.payment_method.kind_of? Spree::Gateway::Payanyway}.payment_method if @order
  end
  
  def complete_or_create_payment(order, gateway)
    return unless order && gateway
    unless (payment = order.payments.last) && payment.complete!
      order.payments.destroy_all
      order.payments.create! do |p|
        p.payment_method = gateway
        p.amount = order.total
        p.state = 'completed'
      end
    end
    order.update!
  end

  def complete_order
    @order.next! until @order.state == "complete"
    @order.update!
  end

end