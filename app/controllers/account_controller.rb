class AccountController < ApplicationController
	
	before_filter :require_login, :except => [:index, :activate, :recover, :resend, :change_email, :skip_activation]
	
	def index
		redirect_after_login and return if @current_user
		if request.post?
			if params[:login]
				@login = params[:login]
				u = User.authenticate @login[:username], @login[:password], session[:noactivation]
				if u
					session[:current_user_id] = u.id
					flash[:notice] = 'You have successfully logged in.'
					@current_user = u
					redirect_after_login
				else
					@errors = ['Invalid login.']
				end
			elsif params[:obj]
				@obj = User.new params[:obj]
				if @obj.save
					session[:register_id] = @obj.id
					if session[:noactivation] 
						@obj.update_attribute :activated, true
						session[:current_user_id] = @obj.id
						flash[:notice] = 'Your account has been created.'
						redirect_after_login
					else
						@obj.create_activation_key
						Notifier.deliver_registered @obj, url_for(:action => :activate, :id => @obj.activation_key)
						redirect_to :action => :activate
					end
				else
					@errors = @obj.errors.full_messages
				end
			elsif params[:lost]
				@lost = params[:lost]
				u = User.find :first, :conditions => ['username = ? or email = ? and deleted = 0', @lost[:username], @lost[:username]]
				if u
					u.create_activation_key
					Notifier.deliver_lost_password u, url_for(:action => :recover, :id => u.activation_key)
					redirect_to :action => :recover
				else
					@errors = ['Sorry, We don\'t have any user on file with that username or password.']
				end
			end
		end
	end
	
	def edit
		@obj = @current_user
		if request.post? and @obj.update_attributes params[:obj]
			flash[:notice] = 'Your account has been updated.'
			redirect_after_login
		end
	end

	def activate
		if params[:id] and !params[:id].to_s.strip.blank?
			u = User.authenticate_by_activation_key params[:id]
			if u
				session[:current_user_id] = u.id
				flash[:notice] = 'Your account has been activated and you have been automatically logged in.'
				@current_user = u
				redirect_after_login
			else
				@errors = ['Invalid key - user not found.']
			end
		end
	end
	
	def recover
		if params[:id] and !params[:id].to_s.strip.blank?
			u = User.authenticate_by_activation_key params[:id]
			if u
				session[:current_user_id] = u.id
				flash[:notice] = 'Account recovery successful. You have been automatically logged in. Please update your account below with a new password.'
				@current_user = u
				redirect_to :action => :edit
			else
				@errors = ['Invalid key - user not found.']
			end
		end
	end
	
	def applications
		@current_user.applicants :order => 'applicants.created_at desc', :include => :exams
	end
	
	def logout
		session[:current_user_id] = nil
		flash[:notice] = 'You have successfully logged out.'
		redirect_to :controller => :apply, :action => :index
	end
	
	def redirect_after_login
		if session[:after_login]
			redirect_to session[:after_login]
			session[:after_login] = nil
		else
			if @current_user and @current_user.level >= 10
				redirect_to :controller => :exams
			else
				redirect_to :controller => :applicants
			end
		end
	end
	
	def resend
		@obj = User.find session[:register_id]
		flash[:notice] = 'Activation email has been resent.'
		Notifier.deliver_registered @obj, url_for(:action => :activate, :id => @obj.activation_key)
		redirect_to :action => :activate
	end
	
	def change_email 
		@obj = User.find session[:register_id]
		if request.post?
			if @obj.update_attributes :email => params[:email]			
				flash[:notice] = 'Email has been updated and activation email has been resent.'
				Notifier.deliver_registered @obj, url_for(:action => :activate, :id => @obj.activation_key)
				redirect_to :action => :activate	
			else
				@errors = @obj.errors.full_messages
			end
		end
	end
	
	def skip_activation
		u = User.find session[:register_id]
		u.update_attribute :activated, true
		session[:current_user_id] = u.id
		flash[:notice] = 'Your account has been activated and you have been automatically logged in.'
		@current_user = u
		redirect_after_login
	end
	
end