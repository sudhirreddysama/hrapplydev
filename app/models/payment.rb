require("nokogiri")
class Payment < ActiveRecord::Base

	belongs_to :applicant
	
	def number= v
		@number = v.to_s
		self.number4 = @number[-4, 4]
	end
	attr :number
	attr :verification_value, true
	
	validates_presence_of :number, :first_name, :month, :year, :verification_value
	validates_format_of :month, :year, :with => /\A\d\d\Z/, :allow_blank => true
	
	if Rails.env == "development"
		
		# https://demo.globalgatewaye4.firstdata.com
		# monroe495 <-- old
		# monroe194
		# ad.IS.34.test4
		
		API_URL = 'https://api.demo.globalgatewaye4.firstdata.com/transaction/v24' #v19?
		#GATEWAY_ID = 'PA0472-58'
		#PASSWORD = 'puleAkiPbucRNio65kuk1TYHrKAmvE1h'
		#KEY_ID = '586124'
		#HMAC_KEY = '_HTQa~KN8ja55H4Qo5bucQ1ml9lWy6rW'
		GATEWAY_ID = 'OB0846-57'
		PASSWORD = 'Xeqf8R8Bvk282RAgP4SuAAscOUKZGlq7'
		KEY_ID = '635276'
		HMAC_KEY = 'Vx47blmDxfUsx5I8hB8LlYxIic~QrZdh'
	else
		API_URL = 'https://api.globalgatewaye4.firstdata.com/transaction/v24' #v19?
		#GATEWAY_ID = 'D23414-01'
		GATEWAY_ID = 'H27820-43'
		#PASSWORD = 'tsC7ECmsagyewIX9peyCVSdOyRHJdVv2'
		PASSWORD = 'KUq6OI2Wax2a6fJqI5GfWPNHItyD3Rx5'
		#KEY_ID = '354230'
		KEY_ID = '619445'
		#HMAC_KEY = 'KJsFaEXTQT23T5lH92xamtRlx7GnFZTg'
		HMAC_KEY = 'mICSgQh1FXjiCH6pd8S0V8c5XRFjfW4m'
	end
	
	CARD_TYPES = %w{Visa Mastercard Discover}
	
	TYPES = {
		'00' => 'Purchase'
	}
	
	def card_number= v
		@card_number = v
		self.card_last4 = v.to_s[-4, 4]
		self.card_type = case v.to_s[0, 1]
			when '5', '2'; 'Mastercard'
			when '4'; 'Visa'
			when '6'; 'Discover'
		end
	end
	
	def build_next attr = {}
		p = Payment.new attr
		p.set_previous self
		return p
	end
	
	def set_previous v
		self.previous = v
		self.card_type = v.card_type
		self.card_name = v.card_name
		self.card_date = v.card_date
		self.card_last4 = v.card_last4
		self.prev_type = v.transaction_type
		self.prev_authorization_num = v.authorization_num
		self.prev_transaction_tag = v.transaction_tag
		self.prev_transarmor_token = v.transarmor_token
		return v
	end
	
	def purchase
		do_post('00') { |t| set_card_data t }
	end
	before_save :purchase
	
	def set_card_data t
		t.CardType typ if !typ.blank?
		t.DollarAmount formatted_dollar_amount
		t.Expiry_Date month+""+year
		t.CardHoldersName first_name
		t.CVD_Presence_Ind(verification_value ? '1' : '0')
		t.CVDCode verification_value if !verification_value.blank?
		t.Address { |a|
			a.Address1 address if !address.blank?
			a.City city if !city.blank?
			a.State state if !state.blank?
			a.Zip zip if !zip.blank?
		}
		card_number_or_transarmor_token t
	end
	
	def set_tag_amount_and_num t
		t.Transaction_Tag prev_transaction_tag
		t.DollarAmount formatted_dollar_amount
		t.Authorization_Num prev_authorization_num
	end
	
	def card_number_or_transarmor_token(t)
		if number.blank?
			t.TransarmorToken prev_transarmor_token
		else
			t.Card_Number number
		end
	end
	
	def error_message
		return nil if transaction_approved
		err = nil
		err = exact_message if exact_code.to_i != 0
		err = bank_message if err.blank?
		err = response_body if err.blank?
		err = 'Credit card payment failed.' if err.blank?
		return err
	end
	
	def do_post type_code
		# self.transaction_type = type_code
		method = 'POST'
		content_type = 'application/xml'
		uri = URI.parse API_URL
		# self.request_datetime = Time.now
		time = Time.now.utc.strftime '%Y-%m-%dT%H:%M:%SZ'
		# time = request_datetime.utc.strftime '%Y-%m-%dT%H:%M:%SZ'
		builder = Nokogiri::XML::Builder.new { |xml|
			xml.Transaction { |t|
				t.ExactID GATEWAY_ID
				t.Password PASSWORD
				t.Transaction_Type type_code
				yield t
			}
		}
		content = builder.to_xml
		hashed_content = Digest::SHA1.hexdigest content
		data = method + "\n" + content_type + "\n" + hashed_content + "\n" + time + "\n" + uri.request_uri
		hmac = Base64.encode64(OpenSSL::HMAC.digest('sha1', HMAC_KEY, data))
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		request = Net::HTTP::Post.new(uri.request_uri)
		request['X-GGE4-DATE'] = time
		request['X-GGE4-CONTENT-SHA1'] = hashed_content
		request['Content-Length'] = content.size
		request['Content-Type'] = content_type
		request['Authorization'] = 'GGE4_API ' + KEY_ID + ':' + hmac.strip
		response = http.request(request, content)
		self.request_body = content.sub(/<Card_Number>\d+(\d{4})</, '<Card_Number>************\1<').sub(/<CVDCode>\d+</, '<CVDCode>***<')
		self.response_code = response.code
		self.response_body = response.body.to_s.sub(/<CVDCode>\d+</, '<CVDCode>***<')
		if response_code.to_s[0, 1] == '2'
			xml = Nokogiri::Slop(response.body)
			r = xml.TransactionResult
			# self.receipt = r.CTR.text
			# self.authorization_num = r.Authorization_Num.text
			# self.transaction_tag = r.Transaction_Tag.text
			a = r.Transaction_Approved.text
			self.transaction_approved = (a == 'true' || a == '1')
			# self.transarmor_token = r.TransarmorToken.text
			# self.bank_code = r.Bank_Resp_Code.text
			# self.bank_message = r.Bank_Message.text
			# self.exact_code = r.EXact_Resp_Code.text
			# self.exact_message = r.EXact_Message.text
		end
		# Up to controlling code to save since we're probably in the middle of a commit that might be rolled back.
		return transaction_approved
	end
	
end