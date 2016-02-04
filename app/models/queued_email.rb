class QueuedEmail < ActiveRecord::Base

	serialize :email

	def self.cron
		logger.info "Queued Email Cron Start"
		QueuedEmail.find(:all, :limit => 10).each { |qm|
			logger.info "Sending Email..."
			Notifier.deliver(qm.email)
			qm.destroy
			logger.info "Email Sent..."
		}
		logger.info "Queued Email Cron End"
		Rails.logger.flush
	end

end