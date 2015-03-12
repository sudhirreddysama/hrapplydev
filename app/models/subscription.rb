class Subscription < ActiveRecord::Base

	has_and_belongs_to_many :new_categories
	
	def validate
		errors.add_to_base 'Please enter your email' if email.blank?
		errors.add_to_base 'Please select at least one category' if new_category_ids.empty?
	end
		
	def before_create
		old = Subscription.find_by_email email
		old.destroy if old
		return true
	end
	
	def self.cron
		logger.info 'Beginning Cron'
		exam_conditions = 'exams.notified = 0 and (exams.publish < now() or exams.publish is null) and (exams.deadline > now() or exams.deadline is null) and exams.published = 1'
		@objs = Subscription.find :all, :include => {:new_categories => :exams}, :conditions => exam_conditions
		connection.reconnect!
		Exam.update_all 'exams.notified = 1', exam_conditions
		@objs.each { |o|
			exams = []
			o.new_categories.each { |c|
				exams += c.exams
			}
			exams.uniq!
			logger.info 'Sending Subscription'			
			begin
				Notifier.deliver_subscription o, exams
			rescue
				logger.info 'Could Not Deliver'
			end
			logger.info o.inspect
			logger.info exams.inspect
		}
		Rails.logger.flush
	end
	
	def self.test
		logger.info 'Logging Works!'
		Rails.logger.flush
	end
	
end