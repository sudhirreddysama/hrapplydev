class TestController < ApplicationController

	def index
		output = IO.popen('which convert')
		render :text => output.readlines[0]
	end

end