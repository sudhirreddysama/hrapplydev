class SubscribeController < ApplicationController

	def index
		@objs = NewCategory.find :all, :order => :name
		@obj = Subscription.new params[:obj]
		if request.post? and @obj.save
			flash[:notice] = 'You have successfully subscribed to our email notification service. You should begin receiving emails for exams / jobs posted in the categories you have selected.'
			redirect_to :controller => :apply
		end
	end
	
	def remove
		if request.post?
			@obj = Subscription.find_by_email params[:email]
			if @obj
				@obj.destroy
				flash[:notice] = 'You have successfully been removed from our email notification service.'
				redirect_to :controller => :apply
			else
				@not_found = true
			end
		end
	end

end