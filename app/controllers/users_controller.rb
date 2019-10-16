class UsersController < ApplicationController
	
	def rl
		require_level 20
	end
	before_filter :rl, :except => :view

	def index
		@filter = params[:filter] || flash[:users_filter]
		@filter = {} if !@filter or @filter[:clear]
		flash[:users_filter] = @filter
		cond = get_search_conditions @filter[:search], {'users.username' => :like, 'users.first_name' => :like, 'users.last_name' => :like}
		cond << 'users.deleted = 0'
		@objs = User.paginate(
			:page => params[:page], 
			:conditions => get_where(cond), 
			:order => 'users.username asc')
	end
	
	def view
		@obj = User.find params[:id], :conditions => {:deleted => false}
	end
	
	def new
		@obj = User.new params[:obj]
		if request.post? and @obj.save
			flash[:notice] = 'User has been saved'
			redirect_to :action => :index
		end
	end
	
	def edit
		@obj = User.find params[:id], :conditions => {:deleted => false}
		if request.post? and @obj.update_attributes params[:obj]
			flash[:notice] = 'User has been saved'
			redirect_to :action => :index
		end
	end
	
	def delete
		@obj = User.find params[:id], :conditions => {:deleted => false}
		if request.post?
			@obj.fake_destroy
			flash[:notice] = 'User has been deleted.'
			redirect_to :action => :index
		end
	end
	
	def switch
		session[:current_user_id] = params[:id]
		render :text => 'switched'
	end

end