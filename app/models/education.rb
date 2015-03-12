class Education < ActiveRecord::Base

	belongs_to :applicant
	
	attr :do_validation, true
	
	validates_presence_of :school_name, :state, :major, :degree, :if => :do_validation
	validates_presence_of :credits_semester, :if => Proc.new { |e| e.do_validation and e.credits_quarter.blank? }
	validates_presence_of :credits_quarter, :if => Proc.new { |e| e.do_validation and e.credits_semester.blank? }
	
end