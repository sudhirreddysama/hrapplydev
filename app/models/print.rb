class Print < ActiveRecord::Base
	
	belongs_to :exam_type
	
	def filepath
		"prints/#{id}.pdf"
	end

end