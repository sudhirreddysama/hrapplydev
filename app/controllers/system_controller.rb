class SystemController < ApplicationController

	before_filter :rl; def rl; require_level 20; end

	def index
		@obj = @system
		if request.post? and @obj.update_attributes params[:obj]
			flash[:notice] = 'System settings saved.'
			redirect_to {}
		end
	end

end