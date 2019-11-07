class CsPerson < ActiveRecord::Base
	
	set_table_name "#{MCCSDB}.people"
	
	has_many :cs_applicants, :foreign_key => 'person_id'
	
end