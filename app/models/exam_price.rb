class ExamPrice < ActiveRecord::Base

	belongs_to :applicant
	belongs_to :exam
	
	attr :remove, true

end