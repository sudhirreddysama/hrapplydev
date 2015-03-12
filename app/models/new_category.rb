class NewCategory < ActiveRecord::Base

	has_and_belongs_to_many :subscriptions
	has_and_belongs_to_many :exams
		
end