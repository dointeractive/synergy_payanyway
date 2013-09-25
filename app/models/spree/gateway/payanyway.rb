class Spree::Gateway::Payanyway < Spree::Gateway
  preference :id, :string
  preference :currency_code, :string, :default => 'RUB'
  preference :signature, :string
  preference :locale, :string, :default => 'ru'
  preference :payment_system, :string
  preference :payment_system_list, :string

  attr_accessible :preferred_id, :preferred_currency_code, :preferred_signature,
      :preferred_locale, :preferred_payment_system, :preferred_payment_system_list

  def method_type
    'payanyway'
  end

  def url
    'https://www.moneta.ru/assistant.htm'
  end

  def mode
    test? ? 1 : 0
  end

  def test?
    options[:test_mode] == true
  end

  def self.current
    self.where(:type => self.to_s, :environment => Rails.env, :active => true).first
  end

  def source_required?
    false
  end

  def signature(order)
    Digest::MD5.hexdigest([
        options[:id],
        order.id,
        format("%.2f", order.total),
        options[:currency_code],
        mode,
        options[:signature]
      ].join)
  end

  def url_for_order(order, opt = {})
    params = []
    params << "MNT_ID=#{options[:id]}"
    params << "MNT_TRANSACTION_ID=#{order.id}"
    params << "MNT_CURRENCY_CODE=#{options[:currency_code]}"
    params << "MNT_AMOUNT=#{format("%.2f", order.total)}"
    params << "MNT_TEST_MODE=#{mode}"
    params << "MNT_SIGNATURE=#{signature(order)}"
    params << "moneta.locale=#{options[:locale]}" if options[:locale].present?
    params << "paymentSystem.unitId=#{opt[:payment_system].presence || options[:payment_system]}" if opt[:payment_system].present? || options[:payment_system].present?
    params << "paymentSystem.limitIds=#{options[:payment_system_list]}" if options[:payment_system_list].present?
    params << "followup=true"
    [options[:server], params.join('&')].join('?')
  end

end
