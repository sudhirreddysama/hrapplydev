class Employment < ActiveRecord::Base

	belongs_to :applicant
	
	attr :remove, true
	
	attr :do_validation, true
	
	validates_presence_of :name, :address, :city, :state, :zip, :start_date, :end_date, :salary, :hours, :reason_left, :title, :supervisor_name, :supervisor_title, :supervisor_phone, :description, :if => :do_validation

end