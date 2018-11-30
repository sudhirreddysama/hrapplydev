# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '11b15a28357f06c1da1fdaccaf9bad9c'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

	skip_before_filter :verify_authenticity_token

	include SslRequirement
  include ExceptionNotifiable
  local_addresses.clear

	def ssl_required?
		true
		#RAILS_ENV == 'production'
	end
  
	def load_current_user
	
		# Quick fix - large posts (like file uploads) will timeout the DB connection.
		if request.post?
			ActiveRecord::Base.connection.reconnect!
		end
		
		if session[:current_user_id]
			@current_user = User.find_by_id session[:current_user_id], :conditions => ['deleted = 0' + (session[:noactivation] ? '' : ' and activated = 1')]
		end
	end
	before_filter :load_current_user
	
	def require_login
		unless @current_user
			redirect_to :controller => :account, :action => :index
			flash[:after_login] = url_for({})
			flash[:notice] = 'Please log in.'
			return false
		end
		true
	end
	
	def require_level l
		if require_login
			if @current_user.level < l
				render :nothing => true
				return false
			end
		else
			return false
		end
	end
	
  def get_search_conditions search, fields
  	words = search.to_s.split ' '
  	return([]) if words.empty?
  	words.collect { |w|
  		fields.collect { |f, type|
				case type
					when :eq
						DB.escape("(#{f} = '%s')", w)
					when :like
						DB.escape("(#{f} like '%%%s%%')", w)
					when :left
						DB.escape("(#{f} like '%s%%')", w)
				end
  		}.join ' or '
  	}
  end
  
  def get_where c
  	c = c.reject &:blank?
  	return nil if c.empty?
  	'(' + c.join(') and (') + ')'
  end
	
	def check_expired
		Applicant.check_expired
	end
	before_filter :check_expired
  
  def load_system
  	@system = System.find 1
  end
  before_filter :load_system
  
end
