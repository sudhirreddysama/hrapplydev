class User < ActiveRecord::Base
	
	validates_format_of :username, :with => /\A[a-zA-Z0-9_]{3,100}\Z/
	validates_uniqueness_of :username
	validates_email_format_of :email
	validates_uniqueness_of :email
	validates_presence_of :password, :on => :create
	validates_confirmation_of :password, :if => :password
	validates_length_of :password, :minimum => 4, :if => :password
	validates_presence_of :first_name, :last_name, :level
	
	has_many :applicants, :order => 'created_at desc'
	has_many :messages, :foreign_key => :recipient_id
	has_many :sent_messages, :class_name => 'Message', :foreign_key => 'sender_id'
	
	LEVELS = [['customer', 0], ['employee', 10], ['admin', 20]]
	
  def password= v
  	unless v.to_s.empty?
			self.encrypted_password = Digest::SHA1.hexdigest(v)
			@password = v
  	end
  end  
  attr_reader :password
  
  def self.authenticate u, p, noactivation = false
  	find_by_username u, :conditions => ['encrypted_password = ? and deleted = 0' + (noactivation ? '' : ' and activated = 1'), Digest::SHA1.hexdigest(p)]
  end
  
  def self.authenticate_by_activation_key k
  	u = find_by_activation_key k, :conditions => 'deleted = 0 and activation_key is not null and activation_key != ""'
  	return nil unless u
		u.update_attributes :activation_key => '', :activated => true
		u
  end
  
  def fake_destroy
  	update_attribute :deleted, true
  end
  
  def label
  	name
  end
  
  def name
  	"#{first_name} #{last_name}"
  end
  
  def email_with_name 
  	"#{name} <#{email}>"
  end
  
  def create_activation_key
  	begin
  		self.activation_key = Array.new(10) { rand(9).to_s }.join
  	end while User.find_by_activation_key activation_key
  	save
  end
  
end