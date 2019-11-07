class CsApplicant < ActiveRecord::Base
	
	set_table_name "#{MCCSDB}.applicants"
	
	belongs_to :applicant, :foreign_key => 'web_applicant_id'
	belongs_to :cs_person, :foreign_key => 'person_id'
	
end