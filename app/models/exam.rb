class Exam < ActiveRecord::Base

	belongs_to :category
	belongs_to :exam_type
	has_many :exam_prices
	has_many :applicants, :through => :exam_prices
	has_and_belongs_to_many :new_categories
		
	validates_presence_of :name, :exam_type
	
	before_destroy :check_destroy
	
	def check_destroy
		if applicants.length > 0
			errors.add_to_base 'This exam has applicants and can not be deleted.'
			return false
		end
		return true
	end
	
	def label
		name
	end
	
	def ask_fee_waiver
		price.to_f > 0
	end
	
	def ask_crossfiler
		exam_date ? true : false
	end
	
end