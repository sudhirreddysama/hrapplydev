class Payment < ActiveRecord::Base

	belongs_to :applicant
	
	def number= v
		@number = v.to_s
		self.number4 = @number[-4, 4]
	end
	attr :number
	attr :verification_value, true
	
	validates_presence_of :number, :first_name, :last_name, :address, :city, :state, :zip, :month, :year, :typ, :verification_value
	validates_format_of :month, :year, :with => /\A\d\d\Z/, :allow_blank => true
	
	def charge_card
#		ActiveMerchant::Billing::Base.mode = :production

#		g = ActiveMerchant::Billing::PayflowGateway.new({
#			:user => 'csadmin1700',
#			:partner => 'PayPal',
#			:login => 'csadmin1700',
#			:password => 'civserv08'
#		}) 

		g = ActiveMerchant::Billing::Base.gateway(:paypal).new(:login => PAYPAL_LOGIN, :password => PAYPAL_PASSWORD)

		c = ActiveMerchant::Billing::CreditCard.new({
			:first_name => first_name,
    	:last_name => last_name,
    	:month => month.to_i.to_s,
    	:year => "20#{year}",
    	:type	=> typ,
    	:number	=> number.to_s.gsub(' ', ''),
    	:verification_value => verification_value
    })
    #unless c.valid?
    #	errors.add :card_no, 'is invalid.'
    #	return false
    #end
    
    ba = {
    	:name => "#{first_name} #{last_name}",
    	:address1 => address,
    	:address2 => '',
    	:city => city,
    	:state => state,
    	:country => 'US',
    	:zip => zip
    }
    
		res = g.purchase amount.to_f * 100, c, :ip => ip, :billing_address => ba
		
		logger.info 'payment response:'
		logger.info res.success?
		logger.info res.message
		logger.info res.inspect
		
		# PayPal might take too long. Reconnect!
		connection.reconnect!
		
		unless res.success?
			errors.add_to_base res.message
			return false
		end
		return true
		
	end
	before_create :charge_card

end