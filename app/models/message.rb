class Message < ActiveRecord::Base

	belongs_to :sender, :class_name => 'User', :foreign_key => :sender_id
	belongs_to :recipient, :class_name => 'User', :foreign_key => :recipient_id
	has_and_belongs_to_many :users
	
	validates_presence_of :subject, :body, :from_email, :to_email, :unless => :dont_send
	validates_email_format_of :from_email, :to_email

	attr :dont_send, true
	
	def save_and_send
		return if dont_send and !(dont_send == '0')
		Notifier.deliver_message self
		save
	end
	
	def label
		"Message ##{id}"
	end
		
end