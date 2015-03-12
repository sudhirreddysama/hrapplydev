class ErrorController < ApplicationController

	def index
		raise Exception.new('test exception thrown!');
	end

end